# -----------------------------------------------------
# Login shell configuration
# -----------------------------------------------------
# macOS Homebrew
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Python management
if command -v pyenv > /dev/null; then
    export PYENV_ROOT="${XDG_DATA_HOME}/pyenv"
    path=("$PYENV_ROOT/bin" $path)
    eval "$(pyenv init -)"
fi

# Node.js management
if command -v fnm > /dev/null; then
    eval "$(fnm env --use-on-cd)"
fi

# Rust environment
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Bun
[[ -f "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# GPG
# export GPG_TTY=$(tty)