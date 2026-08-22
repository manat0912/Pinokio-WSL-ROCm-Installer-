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
   ↳ WSL2 (Ubuntu 24.04)
       ↳ Pinokio Backend (ROCm / AI apps)
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

## Project Roadmap

### Phase 1 — Optimization (Completed)
- [x] Fix WSLg / X11 compositor latency.
- [x] Fix ROCm queue stalls and memory contention.
- [x] Optimize Pinokio launch pipeline (`start.js` / `install.js`).
- [x] Configure zero-swap memory footprint.
- [x] Automatic Pinokio v8.0.40 download and installation in WSL2.

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