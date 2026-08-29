#!/bin/bash
# ==============================================================================
# Pinokio ROCm-on-WSL2 DXG env hook installer
# ------------------------------------------------------------------------------
# AMD ROCm on WSL2 does NOT use /dev/kfd (native Linux). It uses the DirectX
# bridge "ROCDXG" (librocdxg) through /dev/dxg. PyTorch only detects the GPU
# when HSA_ENABLE_DXG_DETECTION=1 is set.
#
# This script installs that env var into conda's activate.d so EVERY Pinokio
# shell.run (which does "conda activate base") inherits it automatically.
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

AD="$MINICONDA/etc/conda/activate.d"
mkdir -p "$AD"

cat > "$AD/rocm_dxg.sh" << 'EOF'
# RDNA4 (gfx1200/gfx1201) optimization environment for AMD Radeon AI PRO R9700
# Applied globally to all conda environments in Pinokio WSL

# Enable DXG detection for ROCm on WSL2
export HSA_ENABLE_DXG_DETECTION=1

# Target RDNA4 architecture (gfx1200 for RDNA4 base, gfx1201 for R9700 specific)
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

# Force CUDA/ROCM dual-path for xFormers build compatibility
export FORCE_CUDA=1
export FORCE_ROCM=1

# ROCm memory allocator: split memory into 512MB blocks to reduce fragmentation
# during VAE decode (22B transformer still resident -> no contiguous block).
export PYTORCH_HIP_ALLOC_CONF="max_split_size_mb:512"
export PYTORCH_ROCM_ALLOC_CONF="max_split_size_mb:512"
EOF

echo "[*] Installed ROCm DXG + RDNA4 env hook -> $AD/rocm_dxg.sh"
echo "[*] All RDNA4 + allocator vars will now apply to every conda activation."