#!/bin/bash
# ==============================================================================
# setup_amd_optimizations.sh — AMD ROCm/WSL2 system-level optimizations.
#
# Run with:  sudo bash setup_amd_optimizations.sh
#
# 1. Redis server (unix socket)   — for redis>=5.0.8 Python client.
# 2. OpenBLAS + BLIS              — faster NumPy/SciPy BLAS.
# 3. llama.cpp compiled with HIP  — GGUF inference on AMD (ROCm/HIP + Vulkan).
# 4. uvloop                      — fast asyncio event loop (already pip-installed).
# ==============================================================================
set -e

echo "[*] AMD ROCm/WSL2 system optimizations"

# ---------------------------------------------------------------------------
# 1. Redis (unix socket)
# ---------------------------------------------------------------------------
if command -v redis-server >/dev/null 2>&1; then
    echo "[*] redis-server already installed."
else
    echo "[*] Installing redis-server..."
    apt-get update -y
    apt-get install -y redis-server
fi
# Enable a unix socket for low-latency local IPC.
if ! grep -q "unixsocket /var/run/redis/redis.sock" /etc/redis/redis.conf 2>/dev/null; then
    mkdir -p /var/run/redis
    cat >> /etc/redis/redis.conf <<'EOF'

# Unix socket (fast local IPC, used by Maestro Redis backend)
unixsocket /var/run/redis/redis.sock
unixsocketperm 777
EOF
fi
systemctl enable --now redis-server 2>/dev/null || service redis-server start 2>/dev/null || true
echo "[*] Redis configured with unix socket /var/run/redis/redis.sock"

# ---------------------------------------------------------------------------
# 2. OpenBLAS / BLIS for NumPy/SciPy
# ---------------------------------------------------------------------------
echo "[*] Installing OpenBLAS + BLIS..."
apt-get install -y libopenblas-dev libblis-dev 2>/dev/null || apt-get install -y libopenblas-dev || true
echo "[*] OpenBLAS installed. Rebuild NumPy/SciPy against it with:"
echo "    pip install --force-reinstall numpy scipy --no-binary numpy,scipy"
echo "    (or set OPENBLAS_NUM_THREADS=n in your env)"

# ---------------------------------------------------------------------------
# 3. llama.cpp with HIP (ROCm) — GGUF inference
# ---------------------------------------------------------------------------
LLAMA_DIR="${LLAMA_DIR:-$HOME/llama.cpp}"
if [ -x "$LLAMA_DIR/build/bin/llama-cli" ] || [ -x "$LLAMA_DIR/build/bin/main" ]; then
    echo "[*] llama.cpp already built at $LLAMA_DIR"
else
    echo "[*] Cloning llama.cpp..."
    git clone --depth=1 https://github.com/ggerganov/llama.cpp.git "$LLAMA_DIR" || true
    cd "$LLAMA_DIR"
    echo "[*] Compiling llama.cpp with HIP (ROCm) for gfx1201..."
    # Modern flag is -DGGML_HIP=ON; older builds used -DLLAMA_HIPBLAS=ON -DLLAMA_HIP=ON
    cmake -B build -DGGML_HIP=ON -DGGML_VULKAN=ON -DAMDGPU_TARGETS=gfx1201 -DCMAKE_BUILD_TYPE=Release
    cmake --build build --config Release -j"$(nproc)"
    echo "[*] llama.cpp built at $LLAMA_DIR/build/bin/"
fi

# ---------------------------------------------------------------------------
# 4. uvloop (Python) — note
# ---------------------------------------------------------------------------
echo "[*] uvloop is a pip package (already in requirements.txt). Enable it per-app:"
echo "    import asyncio, uvloop; asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())"

echo ""
echo "[*] Done. FFmpeg (VAAPI/Vulkan) is already provided by the system ffmpeg."
