# ========================================================================
# Python Development Environment Setup
# ========================================================================
# https://www.python.org/ and https://astral.sh/uv

# Source common utilities if not already loaded
[[ -f "$ZDOTDIR/utils.zsh" ]] && source "$ZDOTDIR/utils.zsh"

# Python environment variables
export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc"
export PYTHONDONTWRITEBYTECODE=1 # Don't create .pyc files

# UV Package Manager (https://astral.sh/uv)
# Installation check and setup
# if ! has_command uv; then
#   log_info "Installing uv Python package manager..."
#   curl -LsSf https://astral.sh/uv/install.sh | sh

#   # Uncomment if needed to add uv to PATH for current session
#   # if [[ -d "$HOME/.cargo/bin" ]] && [[ -x "$HOME/.cargo/bin/uv" ]]; then
#   #   path_add "$HOME/.cargo/bin"
#   #   log_info "uv installed and available in PATH"
#   # fi
# fi

# PyEnv configuration
# Uncomment to enable PyEnv support
# if [[ -d "$HOME/.pyenv" ]]; then
#   export PYENV_ROOT="$HOME/.pyenv"
#   path_add "$PYENV_ROOT/bin"
#   eval "$(pyenv init --path)"
# fi
