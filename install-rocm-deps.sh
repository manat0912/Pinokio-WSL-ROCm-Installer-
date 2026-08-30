#!/bin/bash
# ==============================================================================
# install-rocm-deps.sh — install the ROCm stack + PyTorch for the detected GPU.
#
# Auto-detects RDNA2 / RDNA3 / RDNA4 and installs the matching AMD ROCm stack
# (via amdgpu-install) plus PyTorch ROCm wheels for that gfx target.
#
# Env overrides (optional):
#   ROCM_USE_CASE   e.g. "wsl,rocm" (default "wsl,rocm")
#   TORCH_INDEX_URL e.g. "https://download.pytorch.org/whl/rocm7.0"
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/gpu-detect.sh" ]; then
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/gpu-detect.sh"
fi

ROCM_USE_CASE="${ROCM_USE_CASE:-wsl,rocm}"

echo "===================================================================="
echo "  Installing ROCm + PyTorch for detected GPU: ${AMD_GPU_GEN:-unknown}"
echo "===================================================================="

# --- 1. AMD ROCm stack via amdgpu-install -----------------------------------
# RDNA3 (gfx110x) and RDNA4 (gfx120x) are supported by AMD's WSL ROCm stack.
# RDNA2 (gfx103x) is NOT officially supported; it relies on the gfx override
# set by gpu-detect.sh (HSA_OVERRIDE_GFX_VERSION=10.3.0) + community wheels.
if command -v amdgpu-install >/dev/null 2>&1; then
    echo "[*] Installing AMD ROCm stack (usecase=$ROCM_USE_CASE, $AMD_GPU_GEN)..."
    sudo amdgpu-install --usecase="$ROCM_USE_CASE" --no-dkms --accept-eula
else
    echo "[!] amdgpu-install not found. Install it first from AMD:"
    echo "    https://repo.radeon.com/amdgpu-install/latest/ubuntu/amdgpu-install_*.deb"
fi

# --- 2. PyTorch ROCm wheels ------------------------------------------------
# Pick a torch index URL for the arch. Override with TORCH_INDEX_URL if needed.
if [ -z "$TORCH_INDEX_URL" ]; then
    case "${AMD_GPU_GEN:-RDNA3}" in
        RDNA4) TORCH_INDEX_URL="https://download.pytorch.org/whl/rocm7.0" ;;
        RDNA3) TORCH_INDEX_URL="https://download.pytorch.org/whl/rocm6.2" ;;
        RDNA2) TORCH_INDEX_URL="https://download.pytorch.org/whl/rocm6.2" ;;
        *)     TORCH_INDEX_URL="https://download.pytorch.org/whl/rocm6.2" ;;
    esac
fi

echo "[*] Installing PyTorch for $AMD_GPU_GEN from $TORCH_INDEX_URL"
pip install --upgrade torch torchvision --index-url "$TORCH_INDEX_URL"

echo ""
echo "===================================================================="
echo "  ROCm + PyTorch installed for $AMD_GPU_GEN (gfx $GFX_OVERRIDE)"
echo "  Verify with: python -c 'import torch; print(torch.cuda.is_available())'"
echo "===================================================================="
