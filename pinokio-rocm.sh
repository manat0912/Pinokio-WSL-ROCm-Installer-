#!/bin/bash

# ==============================================================================
# Pinokio ROCm Zero-Lag Launcher Engine
# Multi-architecture: AMD RDNA2 / RDNA3 / RDNA4 (auto-detected)
# Developer: Mana Turipa (Open Source)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/gpu-detect.sh" ]; then
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/gpu-detect.sh"
elif [ -f "$HOME/pinokio/gpu-detect.sh" ]; then
    source "$HOME/pinokio/gpu-detect.sh"
fi

export DISPLAY=:0
export ROCM_USE_WSL=1
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
export MIOPEN_FIND_MODE=FAST

unset NODE_OPTIONS
touch ~/.hushlogin 2>/dev/null || true

echo "===================================================================="
echo "       Pinokio ROCm High-Performance Launcher (Active)"
echo "            GPU: ${AMD_GPU_GEN:-auto} (gfx ${GFX_OVERRIDE:-auto})"
echo "              Developer: Mana Turipa (Open Source)"
echo "===================================================================="
echo ""
echo "[*] AMD ROCm compute environment initialized (${AMD_GPU_GEN:-auto})."
echo "[*] X11 display bypass & Electron latency optimizations active."
echo "[*] Web Interface: http://localhost:42000"
echo ""

PINOKIO_PID=$(pgrep -f "pinokio-bin" | head -n 1)

# Ensure browser bridge is active
if command -v /usr/local/bin/wsl-browser-bridge >/dev/null 2>&1; then
    (/usr/local/bin/wsl-browser-bridge "http://localhost:42000" >/dev/null 2>&1 &)
fi

if [ -n "$PINOKIO_PID" ]; then
    echo "[?] Pinokio ROCm is currently active (PID: $PINOKIO_PID)."
    echo "[*] Focused Pinokio Electron window and opened browser."
    /opt/Pinokio/pinokio-bin --ozone-platform=x11 --disable-gpu-sandbox 2>/dev/null || true
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
    cd /home/manat/pinokio 2>/dev/null || cd /opt/Pinokio 2>/dev/null || true
    if [ -x /opt/Pinokio/pinokio-bin ]; then
        exec /opt/Pinokio/pinokio-bin --ozone-platform=x11 --disable-gpu-sandbox "$@"
    elif [ -x /usr/bin/pinokio ]; then
        exec /usr/bin/pinokio --ozone-platform=x11 --disable-gpu-sandbox "$@"
    else
        cd /home/manat/pinokio
        exec node start.js "$@"
    fi
fi
