# Pinokio ROCm WSL Optimization & One-Click Installer Project

[![Hardware](https://img.shields.io/badge/Hardware-AMD%20AI%20Pro%209700-red.svg)](https://www.amd.com)
[![Platform](https://img.shields.io/badge/Platform-WSL%202%20%7C%20Windows%2011-blue.svg)](https://learn.microsoft.com/windows/wsl/)
[![Acceleration](https://img.shields.io/badge/Acceleration-ROCm%207.2-purple.svg)](https://rocm.docs.amd.com/)
[![Pinokio](https://img.shields.io/badge/Pinokio-v8.0.40-green.svg)](https://github.com/pinokiocomputer/pinokio)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

An optimized environment and automated one-click installer for running **Pinokio** with native **AMD ROCm** acceleration inside **WSL 2** on the **AMD AI Pro 9700 (gfx1201)**. This project completely eliminates the UI, compositor, and disk I/O lag inherent in standard WSL-ROCm setups, providing zero-latency model execution (`start.js`, `install.js`) and high-throughput inference.

---

## Architecture

```
Windows (Pinokio GUI)
   │
   └─→ WSL2 (Ubuntu 24.04)
         │
         └─→ Pinokio Backend (ROCm / AI apps)
```

This architecture provides:
- **Windows**: Pinokio GUI for user interface
- **WSL2**: Pinokio backend with ROCm GPU acceleration
- **Zero lag**: Optimized for AMD AI Pro 9700 (gfx1201)

---

## Objectives & Solved Bottlenecks

| Problem | Root Cause | Solution Applied |
| :--- | :--- | :--- |
| **Interface Lag / UI Stalls** | Wayland/WSLg compositor sync & Electron GPU sandbox | Switched to X11 (`DISPLAY=:0`), `vblank_mode=0`, `ELECTRON_DISABLE_GPU_SANDBOX=1` |
| **Model Install Latency** | 9P cross-filesystem overhead (`/mnt/c/`) & Defender scanning | Enabled `cache=mmap,case=off` in `/etc/wsl.conf` + Windows Defender real-time exclusions |
| **Memory Thrashing / Freezes** | WSL dynamic memory reclaim and swap page faults | Configured `.wslconfig` with `swap=0`, explicit RAM allocation, and `dropcache` |
| **GPU Scheduling Drops** | Host-to-guest PCIe memory contention & Windows TDR | Enabled `HSA_FORCE_FINE_GRAIN_PCIE=1`, `HSA_ENABLE_SDMA=0`, and set `TdrDelay=10` |
| **GPU not detected by PyTorch** | WSL2 ROCm uses `/dev/dxg` (ROCDXG), not `/dev/kfd` | Set `HSA_ENABLE_DXG_DETECTION=1` (see below) |
| **VAE OOM on long videos** | LTX/Open-Sora VAE decodes entire video in one tensor | VRAM-based tiled decoding (512×17 tiles on 32GB) |
| **Generation time limit** | Non-sliding-window models capped at ~4.5 min | Unified `get_max_frames(737)` + multiplier=13 → 10 min |
| **RDNA4 compiler backend** | CK optimized for CDNA, not RDNA4 | Force Triton/AOTriton via `AMDGPU_TARGETS=gfx1200` |

---

## RDNA4 (gfx1201) Optimization Environment

The following environment variables are set globally across all entry points (conda hook, systemd service, launcher) to optimize for **AMD Radeon AI PRO R9700 (gfx1201)**:

```bash
# RDNA4 base architecture target
export AMDGPU_TARGETS="gfx1200"
export PYTORCH_ROCM_ARCH="gfx1200"

# Enable experimental AOTriton-backed attention paths
export TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1

# Force Triton backend for FlashAttention (CK is CDNA-optimized)
export ROCM_FLASH_ATTN_USE_CK=0
export FLASH_ATTENTION_TRITON_AMD_ENABLE=TRUE
export FLASH_ATTN_TRITON=1

# Prefer AOTriton over Composable Kernel for SDPA
export TORCH_ROCM_FA_PREFER_CK=0

# xFormers build compatibility
export FORCE_CUDA=1
export FORCE_ROCM=1
```

**Libraries that benefit:**
| Library | Flag Impact |
|---|---|
| **FlashAttention-2** | Triton backend (not CK) |
| **SageAttention** | AOTriton kernels |
| **xFormers** | Bypass NVCC checks, build for RDNA4 |
| **FlexAttention / TorchCompile** | max-autotune Triton codegen |
| **AOTriton SDPA** | AOTriton > CK |
| **AITER** | Compile for RDNA4 |

---

## Critical GPU-detection fix (ROCm-on-WSL2)

AMD ROCm on WSL2 does **not** expose `/dev/kfd` — that is native Linux only.
It uses the DirectX bridge **ROCDXG** (`librocdxg`) through `/dev/dxg`, and
PyTorch only detects the GPU when this env var is set:

```bash
export HSA_ENABLE_DXG_DETECTION=1
```

The launcher scripts (`pinokio-rocm.sh`, `Pinokio-ROCm.bat`, `optimize_wsl_system.sh`)
now export it automatically, and `setup_rocm_dxg.sh` installs it into conda's
`activate.d` so every Pinokio app inherits it. Verify with:

```bash
python -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"
```

Expected output: `True AMD Radeon AI PRO R9700`

---

## Resumable torch download (flaky-WiFi safe)

The ROCm torch wheel is ~5.4 GB. To survive intermittent WiFi, app install
scripts download it with `wget -c` (resumable) and then `pip install` the local
wheel, instead of a single `pip install --index-url` (which hits pip's 15s
read-timeout):

```bash
wget -c -t 5 --timeout 60 <torch-wheel-url> -O torch.whl
pip install --force-reinstall --no-deps torch.whl
```

---

## AMD PRO Driver Download (AMD AI PRO series)

ROCm-on-WSL2 requires the AMD Software PRO Edition driver. Download it (Windows) with:

```bash
wget https://drivers.amd.com/drivers/prographics/amd-software-pro-edition-26.q3-win11-b.exe -O ~/Downloads/amd-software-pro-edition-26.q3-win11-b.exe
```

Or run the bundled installer (`Install-Pinokio-ROCm.bat`), which downloads it
automatically via `Setup-Pinokio-ROCm.ps1`. Install the `.exe` and reboot before
launching Pinokio.

---

## Hardware Target
- **AMD AI Pro 9700 / AMD Radeon AI PRO R9700 (gfx1201)**

---

## Developer
**Mana Turipa — Open-Source Developer**

---

## One-Click Installation

1. Open the `pinokio rocm` folder.
2. Right-click `Install-Pinokio-ROCm.bat` and select **Run as Administrator**.
3. The installer will automatically:
   - Configure Windows GPU TDR registries (`TdrDelay=10`).
   - Generate the optimized `%USERPROFILE%\.wslconfig`.
   - Add real-time Defender exclusions for WSL virtual disks and processes.
   - Install and update WSL 2 and the Linux ROCm stack.
   - **Download and install Pinokio v8.0.40 (Linux .deb package) in WSL2**
   - Setup Node.js v20 LTS and Pinokio in native storage.
   - Create desktop and launcher shortcuts.
4. Launch Pinokio via the desktop shortcut or `Pinokio-ROCm.bat`.

---

## Pinokio Version

This installer automatically downloads and installs **Pinokio v8.0.40** (Linux .deb package) from:
```
https://github.com/pinokiocomputer/pinokio/releases/download/v8.0.40/Pinokio_8.0.40_amd64.deb
```

The Linux version of Pinokio runs inside WSL2 with full ROCm GPU acceleration, while the Windows version remains as the GUI frontend.

---

## Supported Models (Installer-managed)

The installer provides optimized configurations for these models (model weights downloaded on first use):

| Model Family | Architecture | Key Optimizations |
|---|---|---|
| **Wan 2.1/2.2** | 1.3B, 5B, 14B | 5B config (dim=3072), VRAM tiling, 3-step distilled profiles |
| **Hummingbird-XT** | 5B (ti2v_2_2) | 3-step DMD, lightweight VAE, compatible_model_paths |
| **LTX 2.3 / 2.5** | 19B, 22B | VRAM-based VAE tiling, correct LoRA dirs (ltx2_22B) |
| **Open-Sora 2.0** | STDiT3 (11B) | STDiT3 pipeline, DPM-Solver, Hunyuan VAE, VAE tiling |
| **Minimax H3** | FL2VA/Ref2VA | SDPA attention (SOL requires Triton 3.6+) |
| **SCAIL** | 14B | YOLOX GPU-only (CUDAExecutionProvider) |
| **Hunyuan / Flux / Qwen** | Various | GPU-only, no CPU offload |

**Model weights are NOT included in this repo** — they are downloaded on first use and stored in WSL native storage (`/home/<user>/Maestro/app/ckpts/`) for performance. This repo only contains the installer and configuration scripts.

---

## Project Roadmap

### Phase 1 — Optimization (Completed)
- [x] Fix WSLg / X11 compositor latency.
- [x] Fix ROCm queue stalls and memory contention.
- [x] Optimize Pinokio launch pipeline (`start.js` / `install.js`).
- [x] Configure zero-swap memory footprint.
- [x] Automatic Pinokio v8.0.40 download and installation in WSL2.
- [x] RDNA4 Triton/AOTriton attention backend flags.
- [x] VAE tiling for LTX and Open-Sora (fixes OOM on long videos).
- [x] Unified 10-minute generation limit for all models.

### Phase 2 — Validation & Stress Testing
- [ ] Long-duration multi-model inference tests.
- [ ] PyTorch ROCm wheel verification across diffusers and LLMs.
- [ ] UI responsiveness benchmarking under heavy compute loads.

### Phase 3 — Standalone Package Compilation
- [ ] Compile automated PowerShell suite into a standalone one-click `.exe` / `.msi` wizard.
- [ ] Package pre-configured WSL distro rootfs for offline installations.
- [ ] Implement automatic health checks and driver update monitors.

---

## API Documentation

### Windows to WSL Communication

Pinokio on Windows communicates with the WSL backend via:

```bash
# Launch app in WSL
wsl -d Ubuntu-24.04 -- bash -c "cd ~/app && python server.py"

# Check WSL status
wsl -d Ubuntu-24.04 --status

# Access WSL filesystem from Windows
\\wsl$\Ubuntu-24.04\home\<username>\pinokio
```

### JavaScript (Windows Pinokio)

```javascript
// Launch command in WSL
const { execSync } = require('child_process');
execSync('wsl -d Ubuntu-24.04 -- bash -c "pinokio --version"');
```

### Curl (from Windows)

```bash
# Access Pinokio Web UI running in WSL
curl http://localhost:42000
```

---

## License
This project is open-source and released under the MIT License. Developed by **Mana Turipa**.