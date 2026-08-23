module.exports = {
  daemon: true,
  run: [
    {
      method: "shell.run",
      params: {
        message: "wsl source env/bin/activate && wsl cd app && wsl python launch.py",
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