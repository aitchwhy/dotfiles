# zsh/.zprofile - Login shell configuration
# -----------------------------------------------------------------------------
# Path Configuration
# -----------------------------------------------------------------------------
# Ensure path arrays don't contain duplicates
typeset -U path PATH

# Common paths
path=(
    $HOME/.local/bin
    /usr/local/bin
    /usr/local/sbin
    $path
)

# Homebrew (completions + etc)
if [[ "$(uname -m)" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
fi

# # Rust
# [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
#
# # Node Version Manager
# export NVM_DIR="$XDG_DATA_HOME/nvm"
# [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

# -----------------------------------------------------------------------------
# System specific
# -----------------------------------------------------------------------------
# if [[ "$OSTYPE" == darwin* ]]; then
#     # macOS specific configurations
#     path=(
#         /opt/homebrew/opt/coreutils/libexec/gnubin
#         /opt/homebrew/opt/gnu-sed/libexec/gnubin
#         $path
#     )
# fi

typeset -U path PATH

