# ========================================================================
# Python Development Environment Setup
# ========================================================================

# Python environment variables
export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc" 
export PYTHONDONTWRITEBYTECODE=1  # Don't create .pyc files

# UV Package Manager (https://astral.sh/uv)
# Installation check and setup
if ! command -v uv &>/dev/null; then
  log_info "Installing uv Python package manager..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  
  # Uncomment if needed to add uv to PATH for current session
  # if [[ -d "$HOME/.cargo/bin" ]] && [[ -x "$HOME/.cargo/bin/uv" ]]; then
  #   export PATH="$HOME/.cargo/bin:$PATH"
  #   log_info "uv installed and available in PATH"
  # fi
fi

# PyEnv configuration
# Uncomment to enable PyEnv support
# if [[ -d "$HOME/.pyenv" ]]; then
#   export PYENV_ROOT="$HOME/.pyenv"
#   path=("$PYENV_ROOT/bin" $path)
#   eval "$(pyenv init --path)"
# fi
