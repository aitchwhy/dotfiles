export LANG=en_US.UTF-8
export EDITOR="nvim"
export VISUAL="nvim"

# ====== Path Configuration ======
# Initialize Homebrew on Apple Silicon (this also sets up PATH)
# eval "$(/opt/homebrew/bin/brew shellenv)"
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# PATH Configuration
typeset -U path  # Ensure unique entries
local additional_paths=(
    "$HOME/.local/bin"
    # "$XDG_CONFIG_HOME/bin"
    # "$HOMEBREW_PREFIX/opt/ruby/bin"
    # "$HOMEBREW_PREFIX/opt/python/libexec/bin"
    # "$HOMEBREW_PREFIX/opt/node/bin"
    "$CARGO_HOME/bin"
    "$GOPATH/bin"
    "$PYENV_ROOT/bin"
    # "$HOMEBREW_PREFIX/rustup/bin"
)

for p in $additional_paths; do
    if [[ -d "$p" ]] && [[ ":$PATH:" != *":$p:"* ]]; then
        path+=("$p")
    fi
done
