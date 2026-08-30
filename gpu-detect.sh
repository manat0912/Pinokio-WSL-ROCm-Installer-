#!/bin/bash
# ==============================================================================
# gpu-detect.sh — detect the AMD GPU architecture (RDNA2 / RDNA3 / RDNA4) and
# export the correct ROCm gfx override + WSL DXG flag.
#
# Source this (or run it with `source gpu-detect.sh`). It sets:
#   GFX_OVERRIDE            e.g. 12.0.1 / 11.0.0 / 10.3.0
#   HSA_OVERRIDE_GFX_VERSION
#   HSA_ENABLE_DXG_DETECTION  (WSL2 ROCdxg path)
#   AMD_GPU_GEN            e.g. RDNA4
#
# Detection order:
#   1. GFX_OVERRIDE already set by the Windows installer (authoritative).
#   2. rocminfo gfx arch (works in WSL2 via the DXG driver).
#   3. lspci model name (fallback, may not show host GPU in WSL2).
# ==============================================================================

resolve_from_override() {
    export HSA_OVERRIDE_GFX_VERSION="$GFX_OVERRIDE"
    case "$GFX_OVERRIDE" in
        12.*) export AMD_GPU_GEN="RDNA4" ;;
        11.*) export AMD_GPU_GEN="RDNA3" ;;
        10.*) export AMD_GPU_GEN="RDNA2" ;;
        *)    export AMD_GPU_GEN="RDNA3" ;;
    esac
    export HSA_ENABLE_DXG_DETECTION=1
}

# 1. Authoritative override from the Windows installer.
if [ -n "$GFX_OVERRIDE" ]; then
    resolve_from_override
    return 0 2>/dev/null || exit 0
fi

# 2. rocminfo gfx arch (e.g. "gfx1201" -> major 12).
_gfx=""
if command -v rocminfo >/dev/null 2>&1; then
    _gfx=$(rocminfo 2>/dev/null | grep -oE 'gfx1[0-9]{3}' | head -n 1)
fi

case "$_gfx" in
    gfx12*) GFX_OVERRIDE="12.0.1"; AMD_GPU_GEN="RDNA4" ;;
    gfx11*) GFX_OVERRIDE="11.0.0"; AMD_GPU_GEN="RDNA3" ;;
    gfx10*) GFX_OVERRIDE="10.3.0"; AMD_GPU_GEN="RDNA2" ;;
    *)
        # 3. lspci model-name fallback.
        _gpu_name=$(lspci 2>/dev/null | grep -iE 'vga|display|3d' | grep -i amd | head -n 1)
        case "$_gpu_name" in
            *9700*|*9070*|*9060*|*AI*PRO*) GFX_OVERRIDE="12.0.1"; AMD_GPU_GEN="RDNA4" ;;
            *7900*|*7800*|*7700*|*7600*)    GFX_OVERRIDE="11.0.0"; AMD_GPU_GEN="RDNA3" ;;
            *6900*|*6800*|*6700*|*6600*|*6500*) GFX_OVERRIDE="10.3.0"; AMD_GPU_GEN="RDNA2" ;;
            *) GFX_OVERRIDE="11.0.0"; AMD_GPU_GEN="RDNA3" ;;
        esac
        ;;
esac

export HSA_OVERRIDE_GFX_VERSION="$GFX_OVERRIDE"
export HSA_ENABLE_DXG_DETECTION=1

echo "[*] GPU architecture: $AMD_GPU_GEN (gfx override $GFX_OVERRIDE)"
