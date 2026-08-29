#!/bin/bash
export HOME=/home/manat

mkdir -p /run/pinokio 2>/dev/null
chmod 700 /run/pinokio 2>/dev/null
export XDG_RUNTIME_DIR=/run/pinokio

export DISPLAY=:99
if ! pgrep -x Xvfb > /dev/null; then
  /usr/bin/Xvfb :99 -screen 0 1280x800x24 -nolisten tcp > /tmp/xvfb.log 2>&1 &
  for i in $(seq 1 20); do
    [ -S /tmp/.X11-unix/X99 ] && break
    sleep 0.5
  done
fi

export PATH=/opt/rocm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/wsl/lib
export LD_LIBRARY_PATH=/usr/lib/wsl/lib:/opt/rocm/lib

export HSA_ENABLE_DXG_DETECTION=1
export PYTORCH_HIP_ALLOC_CONF="max_split_size_mb:512"
export PYTORCH_ROCM_ALLOC_CONF="max_split_size_mb:512"
export AMDGPU_TARGETS="gfx1200"
export PYTORCH_ROCM_ARCH="gfx1200"
export TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1
export ROCM_FLASH_ATTN_USE_CK=0
export FLASH_ATTENTION_TRITON_AMD_ENABLE=TRUE
export FLASH_ATTN_TRITON=1
export TORCH_ROCM_FA_PREFER_CK=0
export FORCE_CUDA=1
export FORCE_ROCM=1

export ELECTRON_OZONE_PLATFORM_HINT=x11

cd /home/manat/pinokio
echo "[PINOKIO] starting electron server $(date)"
exec /opt/Pinokio/pinokio-bin --ozone-platform=x11 --no-sandbox --disable-gpu-sandbox
