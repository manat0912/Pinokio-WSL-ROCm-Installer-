module.exports = {
  run: [
    {
      method: "shell.run",
      params: {
        message: "wsl cd ~ && git clone https://github.com/Blizaine/Maestro.git Maestro",
        venv: "env",
        path: "Maestro"
      }
    },
    {
      method: "shell.run",
      params: {
        message: "wsl python3 -m venv env",
        venv: "env",
        path: "Maestro"
      }
    },
    {
      method: "shell.run",
      params: {
        message: "wsl source env/bin/activate && uv pip install -r app/requirements.txt --index-strategy unsafe-best-match",
        venv: "env",
        path: "Maestro"
      }
    },{
      method: "shell.run",
      params: {
        message: "wsl source env/bin/activate && pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.0 && wsl pip install xformers",
        venv: "env",
        path: "Maestro"
      }
    },
    {
      method: "input",
      params: {
        title: "Installation completed",
        description: "Click Start to launch in WSL."
      }
    }
  ]
}