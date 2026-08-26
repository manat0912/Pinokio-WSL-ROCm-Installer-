#!/bin/bash
# ==============================================================================
# Pinokio ROCm Zero-Lag Launcher Engine
# Architecture: Windows Pinokio GUI + WSL2 ROCm Backend
# Target Hardware: AMD AI Pro 9700 (gfx1201)
# Developer: Mana Turipa (Open Source)
# ==============================================================================

export DISPLAY=:0
export ROCM_USE_WSL=1
export HSA_OVERRIDE_GFX_VERSION=12.0.1
export HSA_ENABLE_DXG_DETECTION=1
export TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1
export HSA_ENABLE_SDMA=0
export HSA_FORCE_FINE_GRAIN_PCIE=1
export GPU_MAX_HEAP_SIZE=100
export GPU_MAX_ALLOC_PERCENT=100
export GPU_SINGLE_ALLOC_PERCENT=100
export MESA_NO_ERROR=1
export vblank_mode=0
export ELECTRON_DISABLE_GPU_SANDBOX=1
export ELECTRON_FORCE_WINDOW_MENU_BAR=1
export ELECTRON_OZONE_PLATFORM_HINT=x11
export LD_LIBRARY_PATH=/usr/lib/wsl/lib:/opt/rocm/lib:${LD_LIBRARY_PATH}
export BROWSER=/usr/local/bin/wsl-browser-bridge

# RDNA4 (gfx1200/gfx1201) optimization environment for AMD Radeon AI PRO R9700
export AMDGPU_TARGETS="gfx1200"
export PYTORCH_ROCM_ARCH="gfx1200"
export ROCM_FLASH_ATTN_USE_CK=0
export FLASH_ATTENTION_TRITON_AMD_ENABLE=TRUE
export FLASH_ATTN_TRITON=1
export TORCH_ROCM_FA_PREFER_CK=0
export FORCE_CUDA=1
export FORCE_ROCM=1

unset NODE_OPTIONS
touch ~/.hushlogin 2>/dev/null || true

echo "===================================================================="
echo "       Pinokio ROCm High-Performance Launcher (Active)"
echo "            Optimized for AMD AI Pro 9700 (gfx1201)"
echo "              Developer: Mana Turipa (Open Source)"
echo "===================================================================="
echo ""
echo "[*] AMD ROCm 7.2 & gfx1201 compute environment initialized."
echo "[*] X11 display bypass & Electron latency optimizations active."
echo "[*] RDNA4 Triton/AOTriton attention backends enabled."
echo "[*] Architecture: Windows Pinokio GUI + WSL2 ROCm Backend"
echo ""

# Check if Pinokio is installed via .deb package
PINOKIO_BIN=""
if command -v pinokio >/dev/null 2>&1; then
    PINOKIO_BIN="pinokio"
    echo "[*] Pinokio found at: $(which pinokio)"
elif [ -x /opt/Pinokio/pinokio-bin ]; then
    PINOKIO_BIN="/opt/Pinokio/pinokio-bin"
    echo "[*] Pinokio found at: /opt/Pinokio/pinokio-bin"
elif [ -x /usr/bin/pinokio ]; then
    PINOKIO_BIN="/usr/bin/pinokio"
    echo "[*] Pinokio found at: /usr/bin/pinokio"
else
    echo "[!] Pinokio not found. Please run Setup-Pinokio-ROCm.ps1 first."
    echo "[*] Attempting to install Pinokio..."
    
    # Try to download and install Pinokio
    PINOKIO_DEB_URL="https://github.com/pinokiocomputer/pinokio/releases/download/v8.0.40/Pinokio_8.0.40_amd64.deb"
    PINOKIO_DEB_PATH="/tmp/Pinokio_8.0.40_amd64.deb"
    
    echo "[*] Downloading Pinokio v8.0.40..."
    wget -q "$PINOKIO_DEB_URL" -O "$PINOKIO_DEB_PATH" || {
        echo "[!] Failed to download Pinokio. Please check your internet connection."
        exit 1
    }
    
    echo "[*] Installing Pinokio..."
    sudo dpkg -i "$PINOKIO_DEB_PATH" || sudo apt-get install -f -y
    rm -f "$PINOKIO_DEB_PATH"
    
    if command -v pinokio >/dev/null 2>&1; then
        PINOKIO_BIN="pinokio"
        echo "[*] Pinokio installed successfully!"
    else
        echo "[!] Pinokio installation failed. Please run Setup-Pinokio-ROCm.ps1 again."
        exit 1
    fi
fi

# Set Pinokio home directory
PINOKIO_HOME="$HOME/pinokio"
mkdir -p "$PINOKIO_HOME" 2>/dev/null || true

# Ensure browser bridge is active
if command -v /usr/local/bin/wsl-browser-bridge >/dev/null 2>&1; then
    (/usr/local/bin/wsl-browser-bridge "http://localhost:42000" >/dev/null 2>&1 &)
fi

PINOKIO_PID=$(pgrep -f "pinokio" | head -n 1)

if [ -n "$PINOKIO_PID" ]; then
    echo "[?] Pinokio ROCm is currently active (PID: $PINOKIO_PID)."
    echo "[*] Focused Pinokio Electron window and opened browser."
    "$PINOKIO_BIN" --ozone-platform=x11 --disable-gpu-sandbox 2>/dev/null || true
    echo ""
    echo "[*] Monitoring Pinokio session... (Press Ctrl+C to exit launcher)"
    while kill -0 "$PINOKIO_PID" 2>/dev/null; do
        sleep 2
    done
    echo "[*] Pinokio process ended."
else
    echo "[*] Starting Pinokio ROCm in foreground..."
    echo "[*] (Keep this window open while using Pinokio. Press Ctrl+C to stop)"
    echo "--------------------------------------------------------------------"
    cd "$PINOKIO_HOME" 2>/dev/null || true
    exec "$PINOKIO_BIN" --ozone-platform=x11 --disable-gpu-sandbox "$@"
fi