#!/bin/bash
# ==============================================================================
# Pinokio ROCm-on-WSL2 DXG env hook installer (multi-architecture)
# ------------------------------------------------------------------------------
# AMD ROCm on WSL2 does NOT use /dev/kfd (native Linux). It uses the DirectX
# bridge "ROCDXG" (librocdxg) through /dev/dxg. PyTorch only detects the GPU
# when HSA_ENABLE_DXG_DETECTION=1 is set.
#
# Detects RDNA2 / RDNA3 / RDNA4 and installs a conda activate.d hook so EVERY
# Pinokio shell.run (which does "conda activate base") inherits the right
# gfx override + MIOpen workaround + allocator config automatically.
# ==============================================================================

# Locate the bundled miniconda (Pinokio ships its own)
MINICONDA=""
for c in "$HOME/pinokio/bin/miniconda" "$HOME/miniconda3" "$HOME/miniforge3" "/opt/miniconda3"; do
  if [ -x "$c/bin/conda" ]; then MINICONDA="$c"; break; fi
done

if [ -z "$MINICONDA" ]; then
  echo "[!] Could not locate conda. Skipping activate.d hook."
  echo "[*] Fall back to adding the export to ~/.bashrc instead."
  exit 1
fi

# Detect architecture (honour GFX_OVERRIDE from the Windows installer, else rocminfo)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/gpu-detect.sh" ]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/gpu-detect.sh"
fi
GFX="${GFX_OVERRIDE:-12.0.1}"

AD="$MINICONDA/etc/conda/activate.d"
mkdir -p "$AD"

cat > "$AD/rocm_dxg.sh" << EOF
# AMD ROCm on WSL2 optimization environment (detected gfx $GFX)
# Applied globally to all conda environments in Pinokio WSL

# Enable DXG detection for ROCm on WSL2
export HSA_ENABLE_DXG_DETECTION=1
export HSA_OVERRIDE_GFX_VERSION=$GFX
export ROCM_USE_WSL=1
export HSA_ENABLE_SDMA=0
export HSA_FORCE_FINE_GRAIN_PCIE=1
export HSA_DISABLE_REPLAY=1

# ROCm memory allocator: split into 512MB blocks to reduce fragmentation
# during VAE decode (large transformer still resident -> no contiguous block).
export PYTORCH_CUDA_ALLOC_CONF="garbage_collection_threshold:0.8,max_split_size_mb:512"
export PYTORCH_HIP_ALLOC_CONF="max_split_size_mb:512"
export PYTORCH_ROCM_ALLOC_CONF="max_split_size_mb:512"

# MIOpen: skip exhaustive conv3d solver search (stalls VAE decode on RDNA4).
export MIOPEN_FIND_MODE=FAST

export GPU_MAX_HEAP_SIZE=100
export GPU_MAX_ALLOC_PERCENT=100
export GPU_SINGLE_ALLOC_PERCENT=100
export MESA_NO_ERROR=1
export vblank_mode=0
export LD_LIBRARY_PATH=/opt/rocm/lib:/usr/lib/wsl/lib:\${LD_LIBRARY_PATH}
export BROWSER=/usr/local/bin/wsl-browser-bridge
EOF

echo "[*] Installed ROCm DXG + env hook (gfx $GFX) -> $AD/rocm_dxg.sh"
echo "[*] All ROCm + allocator + MIOpen vars will now apply to every conda activation."
