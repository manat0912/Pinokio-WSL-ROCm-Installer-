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
export PYTORCH_HIP_ALLOC_CONF="max_split_size_mb:512"
export PYTORCH_ROCM_ALLOC_CONF="max_split_size_mb:512"
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
echo "[*] AMD ROCm 7.2 and gfx1201 compute environment initialized."
echo "[*] X11 display bypass and Electron latency optimizations active."
echo "[*] RDNA4 Triton/AOTriton attention backends enabled."
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