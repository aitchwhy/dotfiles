# DevShell Workflow Guide

## Initial Setup (One Time)

1. **Install Nix with flakes enabled**
   ```bash
   # If you don't have Nix installed
   curl -L https://nixos.org/nix/install | sh
   
   # Enable flakes (add to ~/.config/nix/nix.conf)
   echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
   ```

2. **Install direnv**
   ```bash
   nix-env -iA nixpkgs.direnv
   
   # Add to your shell RC file (.bashrc, .zshrc, etc)
   eval "$(direnv hook bash)"  # or zsh
   ```

3. **Setup Google credentials**
   - Follow GOOGLE_CREDENTIALS_SETUP.md to create service account
   - Place JSON file at `~/.config/gcloud/google-docs-service-account.json`

## Daily Workflow

1. **Enter the project directory**
   ```bash
   cd ~/dotfiles/scripts
   ```
   
   direnv will automatically:
   - Load the Nix development shell
   - Set up Python environment
   - Export environment variables
   - Make all tools available

2. **First time in the directory**
   ```bash
   # Allow direnv to load the environment
   direnv allow
   
   # Install Python dependencies
   uv sync
   ```

3. **Run the downloader**
   ```bash
   # Simple run
   uv run python google-docs.py
   
   # Or use the Nix package
   nix run
   ```

## DevShell Features

When you enter the directory, you automatically get:
- Python 3.11 with Google API libraries
- uv (modern Python package manager)
- Development tools: ruff, black, mypy
- Environment variables loaded from .envrc
- Isolated, reproducible environment

## Common Commands

```bash
# Format code
black google-docs.py

# Lint code
ruff check google-docs.py

# Type check
mypy google-docs.py

# Run tests (if you add any)
uv run pytest

# Update dependencies
uv add some-package
uv sync

# Reload environment after .envrc changes
direnv reload
```

## Tips

1. **Custom environment variables**: Create `.envrc.local` for personal overrides
2. **IDE support**: The devshell creates a `.venv` symlink for better IDE integration
3. **Reproducibility**: Anyone with Nix can get the exact same environment
4. **No pollution**: Everything is isolated - won't affect system Python

## Troubleshooting

- **direnv not loading**: Run `direnv allow`
- **Command not found**: Make sure you're in the project directory
- **Credentials error**: Check `GOOGLE_CREDS_PATH` points to valid JSON file
- **Nix errors**: Run `nix flake update` to get latest packages