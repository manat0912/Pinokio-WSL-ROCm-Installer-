#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/gpu-detect.sh" ]; then
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/gpu-detect.sh"
else
    # fallback: default RDNA3 if we cannot detect
    export HSA_OVERRIDE_GFX_VERSION="${HSA_OVERRIDE_GFX_VERSION:-11.0.0}"
    export AMD_GPU_GEN="${AMD_GPU_GEN:-RDNA3}"
    export HSA_ENABLE_DXG_DETECTION=1
fi

GFX="${HSA_OVERRIDE_GFX_VERSION:-11.0.0}"
GEN="${AMD_GPU_GEN:-RDNA3}"

echo "[*] Configuring /etc/wsl.conf for fast I/O caching and fast interop..."
cat << 'EOF' > /etc/wsl.conf
[automount]
enabled = true
options = "metadata,case=off,cache=mmap"
mountFsTab = true

[interop]
enabled = true
appendWindowsPath = false

[boot]
systemd = true
EOF

echo "[*] Adding user 'manat' to video and render groups..."
usermod -aG video,render manat 2>/dev/null || true

echo "[*] Adding ROCm ($GEN, gfx $GFX) environment variables to /home/manat/.bashrc..."
if ! grep -q "ROCM_USE_WSL" /home/manat/.bashrc; then
cat << EOF >> /home/manat/.bashrc

# --- Pinokio ROCm $GEN (gfx $GFX) Optimizations ---
export ROCM_USE_WSL=1
export HSA_OVERRIDE_GFX_VERSION=$GFX
export HSA_ENABLE_DXG_DETECTION=1
export HSA_ENABLE_SDMA=0
export HSA_FORCE_FINE_GRAIN_PCIE=1
export GPU_MAX_HEAP_SIZE=100
export GPU_MAX_ALLOC_PERCENT=100
export GPU_SINGLE_ALLOC_PERCENT=100
export MESA_NO_ERROR=1
export vblank_mode=0
export DISPLAY=:0
export MIOPEN_FIND_MODE=FAST
export ELECTRON_DISABLE_GPU_SANDBOX=1
export ELECTRON_FORCE_WINDOW_MENU_BAR=1
export LD_LIBRARY_PATH=/usr/lib/wsl/lib:/opt/rocm/lib:\${LD_LIBRARY_PATH}
export NODE_OPTIONS="--max-old-space-size=8192 --use-openssl-ca --no-warnings"
EOF
fi

echo "[*] System optimization completed successfully ($GEN, gfx $GFX)!"
