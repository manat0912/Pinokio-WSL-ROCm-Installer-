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
export HSA_ENABLE_DXG_DETECTION=1
export TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1
EOF

echo "[*] Installed ROCm DXG env hook -> $AD/rocm_dxg.sh"
echo "[*] HSA_ENABLE_DXG_DETECTION=1 will now apply to every conda activation."
