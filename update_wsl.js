module.exports = {
  run: [
    {
      method: "shell.run",
      params: {
        message: "git pull",
        path: "Maestro"
      }
    },
    {
      method: "shell.run",
      params: {
        message: "source env/bin/activate && uv pip install -r requirements.txt --index-strategy unsafe-best-match",
        path: "Maestro"
      }
    },
    {
      method: "input",
      params: {
        title: "Update completed",
        description: "Click Start to launch."
      }
    }
  ]
}
