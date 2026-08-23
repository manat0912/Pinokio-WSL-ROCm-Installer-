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
          TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL: "1"
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
