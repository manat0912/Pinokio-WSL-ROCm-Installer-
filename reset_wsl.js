module.exports = {
  run: [
    {
      method: "shell.run",
      params: {
        message: "rm -rf Maestro app/.installed_wsl"
      }
    },
    {
      method: "input",
      params: {
        title: "Reset completed",
        description: "WSL environment reset. Click Install to reinstall."
      }
    }
  ]
}
