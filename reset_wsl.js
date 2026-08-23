module.exports = {
  run: [
    {
      method: "shell.run",
      params: {
        message: "rm -rf ~/Maestro",
        path: "Maestro"
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