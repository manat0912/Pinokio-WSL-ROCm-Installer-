#!/usr/bin/env python3
"""
apply_vae_fix.py — idempotent post-install patch for AMD ROCm video VAEs.

Fixes the RDNA4 (gfx12xx) VAE-decode hang caused by MIOpen's pathological
conv3d solvers. Safe to re-run; each step is guarded by a marker.

What it does:
  1. Detects the AMD GPU architecture (RDNA2 / RDNA3 / RDNA4).
  2. Sets MIOPEN_FIND_MODE=FAST in the conda activation hook (skip exhaustive
     solver search that stalls for 36-48s per new conv shape).
  3. Patches Maestro's wgp.py so every video VAE keeps spatial tiles <= 512px
     on RDNA4 (LTX / WAN / Open-Sora / Hummingbird-XT).

Usage:
  # auto-detect everything (needs the Maestro python env on PATH for torch)
  python apply_vae_fix.py --maestro-app /home/manat/pinokio/api/Maestro.git/Maestro/app

  # pin the arch if torch/rocminfo are not available
  python apply_vae_fix.py --maestro-app /path/to/app --gfx-major 12
"""
import argparse
import os
import re
import subprocess
import sys

CONDA_HOOK_CANDIDATES = [
    "/home/manat/pinokio/bin/miniconda/etc/conda/activate.d/rocm_dxg.sh",
]

# --- arch detection ---------------------------------------------------------

def detect_gfx_major():
    """Return the AMD gfx major version (10=RDNA2, 11=RDNA3, 12=RDNA4)."""
    # 1) torch
    try:
        import torch
        if torch.cuda.is_available():
            return int(torch.cuda.get_device_capability(0)[0])
    except Exception:
        pass
    # 2) rocminfo
    try:
        out = subprocess.run(
            ["rocminfo"], capture_output=True, text=True, timeout=30
        ).stdout
        m = re.search(r"gfx(\d{2,3})", out)
        if m:
            return int(m.group(1)[0:2])
    except Exception:
        pass
    # 3) lspci model name
    try:
        out = subprocess.run(
            ["bash", "-c", "lspci | grep -iE 'vga|display|3d' | grep -i amd"],
            capture_output=True, text=True, timeout=30,
        ).stdout
        return arch_from_name(out)
    except Exception:
        pass
    return 0


def arch_from_name(text: str) -> int:
    t = text.lower()
    if re.search(r"9700|9070|9060|ai pro|rx ?90\d", t):
        return 12  # RDNA4
    if re.search(r"7900|7800|7700|7600|rx ?7\d", t):
        return 11  # RDNA3
    if re.search(r"6900|6800|6700|6600|6500|rx ?6\d", t):
        return 10  # RDNA2
    return 0


# --- conda hook -------------------------------------------------------------

def patch_conda_hook():
    patched = []
    for hook in CONDA_HOOK_CANDIDATES:
        if not os.path.isfile(hook):
            continue
        with open(hook, "r", encoding="utf-8") as f:
            content = f.read()
        if "MIOPEN_FIND_MODE" in content:
            continue
        with open(hook, "a", encoding="utf-8") as f:
            f.write("\n# RDNA4 MIOpen conv3d workaround (VAE decode hang)\n")
            f.write("export MIOPEN_FIND_MODE=FAST\n")
        patched.append(hook)
    return patched


# --- wgp.py -----------------------------------------------------------------

_MIO_MARKER = 'os.environ.setdefault("MIOPEN_FIND_MODE", "FAST")'
_MIO_NEEDLE = 'os.environ["GRADIO_LANG"] = "en"'
_MIO_INSERT = (
    'os.environ["GRADIO_LANG"] = "en"\n'
    '# ROCm/MIOpen: exhaustive conv3d solver search can stall the VAE decode on RDNA4.\n'
    'os.environ.setdefault("MIOPEN_FIND_MODE", "FAST")'
)

_CLAMP_NEEDLE = "    trans = get_transformer_model(wan_model)\n"
_CLAMP_INSERT = (
    "    # RDNA4 (gfx12xx) MIOpen fix: keep every video VAE's spatial tiles <= 512px\n"
    "    # so the decoder convs stay small enough to avoid the pathological slow solver.\n"
    "    if _is_rdna4 and VAE_tile_size is not None:\n"
    "        if isinstance(VAE_tile_size, (tuple, list)):\n"
    "            VAE_tile_size = (int(VAE_tile_size[0]), min(int(VAE_tile_size[1]), 512))\n"
    "        else:\n"
    "            try:\n"
    "                _ts = int(VAE_tile_size)\n"
    "            except (TypeError, ValueError):\n"
    "                _ts = 0\n"
    "            VAE_tile_size = 512 if _ts <= 0 else min(_ts, 512)\n"
    "\n"
    "    trans = get_transformer_model(wan_model)\n"
)

_GFX_NEEDLE = "    device_mem_capacity = torch.cuda.get_device_properties(0).total_memory / 1048576\n"
_GFX_INSERT = (
    "    device_mem_capacity = torch.cuda.get_device_properties(0).total_memory / 1048576\n"
    "    try:\n"
    "        _gfx_major = int(torch.cuda.get_device_capability(0)[0])\n"
    "    except Exception:\n"
    "        _gfx_major = 0\n"
    "    _is_rdna4 = _gfx_major >= 12\n"
)


def patch_wgp(wgp_path):
    with open(wgp_path, "r", encoding="utf-8") as f:
        src = f.read()

    changed = False
    if _MIO_MARKER not in src and _MIO_NEEDLE in src:
        src = src.replace(_MIO_NEEDLE, _MIO_INSERT, 1)
        changed = True

    if "_is_rdna4 = _gfx_major >= 12" not in src and _GFX_NEEDLE in src:
        src = src.replace(_GFX_NEEDLE, _GFX_INSERT, 1)
        changed = True

    if "min(int(VAE_tile_size[1]), 512)" not in src and _CLAMP_NEEDLE in src:
        src = src.replace(_CLAMP_NEEDLE, _CLAMP_INSERT, 1)
        changed = True

    if changed:
        with open(wgp_path, "w", encoding="utf-8") as f:
            f.write(src)
    return changed


# --- main -------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--maestro-app", default=None,
                    help="path to Maestro/app (contains wgp.py)")
    ap.add_argument("--gfx-major", type=int, default=None,
                    help="force gfx major (10=RDNA2, 11=RDNA3, 12=RDNA4)")
    args = ap.parse_args()

    gfx = args.gfx_major if args.gfx_major is not None else detect_gfx_major()
    arch = {10: "RDNA2", 11: "RDNA3", 12: "RDNA4"}.get(gfx, f"gfx{gfx}")
    print(f"[*] Detected AMD GPU architecture: {arch}")

    hooks = patch_conda_hook()
    if hooks:
        print(f"[*] Set MIOPEN_FIND_MODE=FAST in: {', '.join(hooks)}")
    else:
        print("[*] MIOPEN_FIND_MODE already set (or no conda hook found).")

    wgp = args.maestro_app
    if wgp is None:
        for cand in [
            "/home/manat/pinokio/api/Maestro.git/Maestro/app",
        ]:
            if os.path.isfile(os.path.join(cand, "wgp.py")):
                wgp = cand
                break
    if wgp is None:
        print("[!] Could not locate Maestro/app (wgp.py). Pass --maestro-app.")
        return 1

    wgp_path = os.path.join(wgp, "wgp.py")
    if os.path.isfile(wgp_path):
        if patch_wgp(wgp_path):
            print(f"[*] Patched {wgp_path} with the VAE spatial-tiling clamp.")
        else:
            print(f"[*] {wgp_path} already patched.")
    else:
        print(f"[!] wgp.py not found at {wgp_path}")
        return 1

    print("[*] VAE fix applied.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
