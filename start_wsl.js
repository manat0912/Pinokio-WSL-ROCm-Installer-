module.exports = {
  daemon: true,
  run: [
    {
      method: "shell.run",
      params: {
        message: "source env/bin/activate && cd app && python launch.py",
        venv: "env",
        path: "Maestro"
      }
    },
    {
      method: "local.set",
      params: {
        url: "{{input.event[1]}}"
      }
    }
  ]
}