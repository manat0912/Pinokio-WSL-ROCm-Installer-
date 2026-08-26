module.exports = {
  daemon: true,
  run: [
    {
      method: "shell.run",
      params: {
        message: "source env/bin/activate && cd app && python launch.py",
        path: "Maestro",
        env: {
          HSA_ENABLE_DXG_DETECTION: "1",
          TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL: "1",
          AMDGPU_TARGETS: "gfx1200",
          PYTORCH_ROCM_ARCH: "gfx1200",
          ROCM_FLASH_ATTN_USE_CK: "0",
          FLASH_ATTENTION_TRITON_AMD_ENABLE: "TRUE",
          FLASH_ATTN_TRITON: "1",
          TORCH_ROCM_FA_PREFER_CK: "0",
          FORCE_CUDA: "1",
          FORCE_ROCM: "1"
        },
        on: [{
          event: "/http:\\/\\/[0-9.:]+/",
          done: true
        }]
      }
    },
    {
      method: "local.set",
      params: {
        url: "{{input.event[0]}}"
      }
    }
  ]
}