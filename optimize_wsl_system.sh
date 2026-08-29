#!/bin/bash
set -e

echo "===================================================================="
echo " Pinokio ROCm WSL System Optimization Script"
echo " Architecture: Windows Pinokio GUI + WSL2 ROCm Backend"
echo "===================================================================="

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

echo "[*] Adding user to video and render groups..."
CURRENT_USER=$(whoami)
usermod -aG video,render "$CURRENT_USER" 2>/dev/null || true

echo "[*] Creating Pinokio home directory..."
mkdir -p ~/pinokio
mkdir -p ~/.pinokio

echo "[*] Adding ROCm and Pinokio environment variables to ~/.bashrc..."
if ! grep -q "ROCM_USE_WSL" ~/.bashrc; then
cat << 'EOF' >> ~/.bashrc

# --- Pinokio ROCm AMD AI Pro 9700 (gfx1201) Optimizations ---
export ROCM_USE_WSL=1
export HSA_OVERRIDE_GFX_VERSION=12.0.1
export HSA_ENABLE_DXG_DETECTION=1
export TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1
export HSA_ENABLE_SDMA=0
export HSA_FORCE_FINE_GRAIN_PCIE=1
export MESA_NO_ERROR=1
export vblank_mode=0
export DISPLAY=:0
export ELECTRON_DISABLE_GPU_SANDBOX=1
export ELECTRON_FORCE_WINDOW_MENU_BAR=1
export LD_LIBRARY_PATH=/usr/lib/wsl/lib:/opt/rocm/lib:${LD_LIBRARY_PATH}
export NODE_OPTIONS="--max-old-space-size=8192 --use-openssl-ca --no-warnings"

# RDNA4 (gfx1200/gfx1201) optimization for AMD Radeon AI PRO R9700
export AMDGPU_TARGETS="gfx1200"
export PYTORCH_ROCM_ARCH="gfx1200"
export ROCM_FLASH_ATTN_USE_CK=0
export FLASH_ATTENTION_TRITON_AMD_ENABLE=TRUE
export FLASH_ATTN_TRITON=1
export TORCH_ROCM_FA_PREFER_CK=0
export FORCE_CUDA=1
export FORCE_ROCM=1

# ROCm memory allocator: 512MB blocks reduce fragmentation during VAE decode
export PYTORCH_HIP_ALLOC_CONF="max_split_size_mb:512"
export PYTORCH_ROCM_ALLOC_CONF="max_split_size_mb:512"

# Pinokio WSL Backend Configuration
export PINOKIO_HOME="$HOME/pinokio"
export PINOKIO_WSL_BACKEND=true
EOF
fi

echo "[*] Configuring Pinokio for WSL backend mode..."
cat << 'EOF' > ~/.pinokio/config.json
{
  "theme": "dark",
  "home": "/home/$(whoami)/pinokio",
  "version": "8.0.40",
  "wsl_backend": true,
  "gpu": "amd_rocm",
  "hardware": "AMD AI Pro 9700 (gfx1201)"
}
EOF

echo "[*] Setting proper permissions..."
chmod 600 ~/.pinokio/config.json
chmod +x ~/pinokio-rocm.sh 2>/dev/null || true

echo ""
echo "===================================================================="
echo " System optimization completed successfully!"
echo " Architecture: Windows Pinokio GUI + WSL2 ROCm Backend"
echo "===================================================================="
echo ""
echo "Next steps:"
echo "  1. Run Install-Pinokio-ROCm.bat to install Pinokio"
echo "  2. Launch Pinokio using Pinokio-ROCm.bat"
echo "  3. Access Pinokio Web UI at http://localhost:42000"