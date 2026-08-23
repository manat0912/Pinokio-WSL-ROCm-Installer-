module.exports = {
  run: [
    {
      method: "shell.run",
      params: {
        message: "rm -rf Maestro && git clone https://github.com/Blizaine/Maestro.git Maestro"
      }
    },
    {
      method: "shell.run",
      params: {
        message: "python3 -m venv env",
        path: "Maestro"
      }
    },
    {
      method: "shell.run",
      params: {
        venv: "env",
        path: "Maestro",
        message: [
          "uv pip install mmgp==3.7.12 diffusers==0.36.0 transformers==4.57.1 tokenizers==0.22.1 accelerate==1.12.0 tqdm==4.67.3 imageio==2.37.2 imageio-ffmpeg==0.6.0 einops==0.8.2 sentencepiece==0.2.1 open_clip_torch==3.2.0 numpy==2.1.2 num2words==0.5.14 --index-strategy unsafe-best-match",
          "uv pip install moviepy==1.0.3 av==16.1.0 ffmpeg-python pygame==2.6.1 sounddevice==0.5.5 soundfile==0.13.1 mutagen==1.47.0 pyloudnorm==0.2.0 librosa==0.11.0 faster-whisper==1.2.1 openai-whisper==20250625 speechbrain==1.0.3 audio-separator==0.36.1 pyannote.audio==3.3.2 torchcodec==0.10.0 --index-strategy unsafe-best-match",
          "uv pip install gradio==5.29.0 dashscope==1.25.12 loguru s3tokenizer conformer==0.3.2 spacy_pkuseg spacy gradio_rangeslider==0.0.8 opencv-python==4.13.0.92 segment-anything==1.0 rembg==2.0.65 onnxruntime decord==0.6.0 timm==1.0.24 insightface==0.7.3 facexlib==0.3.0 taichi==1.7.4 vector_quantize_pytorch==1.27.19 --index-strategy unsafe-best-match",
          "uv pip install omegaconf==2.3.0 hydra-core==1.3.2 easydict==1.13 pydantic==2.10.6 torchdiffeq==0.2.5 tensordict==0.11.0 peft==0.17.0 vector-quantize-pytorch==1.27.19 matplotlib==3.10.8 gguf==0.17.1 flash-linear-attention==0.4.1 --index-strategy unsafe-best-match",
          "uv pip install ftfy==6.3.1 piexif==1.1.3 nvidia-ml-py==13.590.48 misaki==0.9.4 phonemizer-fork espeakng-loader pydub gitdb==4.0.12 gitpython==3.1.45 stringzilla==4.0.14 xxhash==3.6.0 munch==4.0.0 wetext==0.1.2 json_repair==0.59.5 iopath>=0.1.10 pycocotools --index-strategy unsafe-best-match",
          "uv pip install \"chumpy @ https://github.com/deepbeepmeep/chumpy/releases/download/v0.71/chumpy-0.71-py3-none-any.whl\" \"smplfitter @ https://github.com/deepbeepmeep/smplfitter/releases/download/v0.2.10/smplfitter-0.2.10-py3-none-any.whl\""
        ]
      }
    },
    {
      method: "shell.run",
      params: {
        venv: "env",
        path: "Maestro",
        message: [
          "mkdir -p .wheels && cd .wheels",
          "wget -c -t 5 --timeout 60 https://download.pytorch.org/whl/rocm7.1/torch-2.10.0%2Brocm7.1-cp310-cp310-manylinux_2_28_x86_64.whl -O torch-2.10.0+rocm7.1-cp310-cp310-manylinux_2_28_x86_64.whl",
          "wget -c -t 5 --timeout 60 https://download.pytorch.org/whl/rocm7.1/torchvision-0.25.0%2Brocm7.1-cp310-cp310-manylinux_2_28_x86_64.whl -O torchvision-0.25.0+rocm7.1-cp310-cp310-manylinux_2_28_x86_64.whl",
          "wget -c -t 5 --timeout 60 https://download.pytorch.org/whl/rocm7.1/torchaudio-2.10.0%2Brocm7.1-cp310-cp310-manylinux_2_28_x86_64.whl -O torchaudio-2.10.0+rocm7.1-cp310-cp310-manylinux_2_28_x86_64.whl",
          "pip install --force-reinstall --no-deps torch-2.10.0+rocm7.1-cp310-cp310-manylinux_2_28_x86_64.whl",
          "pip install --force-reinstall --no-deps torchvision-0.25.0+rocm7.1-cp310-cp310-manylinux_2_28_x86_64.whl torchaudio-2.10.0+rocm7.1-cp310-cp310-manylinux_2_28_x86_64.whl",
          "pip install triton==3.5.1 --index-url https://download.pytorch.org/whl/rocm7.1 --timeout 600 --retries 10"
        ]
      }
    },
    {
      method: "shell.run",
      params: {
        message: "mkdir -p app && touch app/.installed_wsl"
      }
    },
    {
      method: "input",
      params: {
        title: "Installation completed",
        description: "Click Start to launch."
      }
    }
  ]
}
