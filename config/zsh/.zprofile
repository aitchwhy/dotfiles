# -----------------------------------------------------------------------------
# ~/.zprofile (Invoked once at login on macOS)
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# ~/.zshenv (???)
# -----------------------------------------------------------------------------

# # XDG Base Directories
# export XDG_CONFIG_HOME="$HOME/.config"
# export XDG_CACHE_HOME="$HOME/.cache"
# export XDG_DATA_HOME="$HOME/.local/share"
# export XDG_STATE_HOME="$HOME/.local/state"
#
# # Ensure directories exist
# mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"
#
# # Core paths
# export DOTFILES="$HOME/dotfiles"
# export CONFIGS="$XDG_CONFIG_HOME"
#
# # Tool configuration paths
# export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
# export STARSHIP_CACHE="$XDG_CACHE_HOME/starship"
# export ATUIN_CONFIG_DIR="$XDG_CONFIG_HOME/atuin"
# export ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij"
# export BAT_CONFIG_PATH="$XDG_CONFIG_HOME/bat/config"
# export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"
#
# # Editor configurations
# export EDITOR="nvim"
# export VISUAL="nvim"
# export PAGER="bat"
# export MANPAGER="sh -c 'col -bx | bat -l man -p'"
#
# # Language configurations
# export LANG="en_US.UTF-8"
# export LC_ALL="en_US.UTF-8"
#
# # History configuration
# export HISTFILE="$XDG_STATE_HOME/zsh/history"
# export HISTSIZE=1000000
# export SAVEHIST=1000000
#
# # Homebrew configuration
# export HOMEBREW_NO_ENV_HINTS=1
# export HOMEBREW_NO_ANALYTICS=1
# export HOMEBREW_AUTOREMOVE=1
# export HOMEBREW_NO_BOTTLE_SOURCE_FALLBACK=1
# export HOMEBREW_NO_INSTALL_CLEANUP=1
# export HOMEBREW_BUNDLE_FILE="$HOME/.Brewfile"
#
# # Additional tool configurations
# export NODE_REPL_HISTORY="$XDG_STATE_HOME/node/repl_history"
# export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/startup.py"
# export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
# export AWS_CONFIG_FILE="$XDG_CONFIG_HOME/aws/config"
# export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME/aws/credentials"



# # ============================================================================ #
# # XDG
# # ============================================================================ #
# export XDG_CONFIG_HOME="$HOME/.config"
# export XDG_CACHE_HOME="$HOME/.cache"
# export XDG_DATA_HOME="$HOME/.local/share"
# export XDG_STATE_HOME="$HOME/.local/state"


# Initialize Homebrew
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Path management function
_add_to_path_if_exists() {
    local dir="$1"
    local position="${2:-append}"
    [[ -d "$dir" ]] || return
    [[ ":$PATH:" == *":$dir:"* ]] && return
    if [[ "$position" == "prepend" ]]; then
        path=("$dir" $path)
    else
        path+=("$dir")
    fi
}

# Set up PATH
typeset -U path PATH

# Core paths
_add_to_path_if_exists "$HOME/.local/bin" "prepend"
_add_to_path_if_exists "$HOMEBREW_PREFIX/bin"
_add_to_path_if_exists "$HOMEBREW_PREFIX/sbin"

# Python - use uv for better performance
export UV_SYSTEM_PYTHON="/opt/homebrew/bin/python3"
_add_to_path_if_exists "$HOME/.local/bin" "prepend"

# Node.js management with volta
export VOLTA_HOME="$HOME/.volta"
_add_to_path_if_exists "$VOLTA_HOME/bin" "prepend"

# Go configuration
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
_add_to_path_if_exists "$GOBIN"

# Rust toolchain
_add_to_path_if_exists "$HOME/.cargo/bin"

# Ruby configuration
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
    _add_to_path_if_exists "/opt/homebrew/opt/ruby/bin" "prepend"
    _add_to_path_if_exists "$(gem environment gemdir)/bin" "prepend"
fi

# Ensure unique PATH
typeset -U PATH path

################
#
# # Reusable Function
# _add_to_path_if_exists() {
#   local dir="$1"
#   local position="${2:-append}"  # default is 'append'
#
#   # Skip if the directory doesn’t exist
#   [[ -d "$dir" ]] || return
#
#   # Skip if already in PATH
#   [[ ":$PATH:" == *":$dir:"* ]] && return
#
#   if [[ "$position" == "prepend" ]]; then
#     path=("$dir" $path)
#   else
#     path+=("$dir")
#   fi
# }
#
# # 1. Homebrew (Apple Silicon) init (Homebrew docs recommend adding directly)
# if [[ -x /opt/homebrew/bin/brew ]]; then
#   eval "$(/opt/homebrew/bin/brew shellenv)"
# fi
#
#
# # PATH Configuration
# typeset -U path PATH  # Ensure unique entries
#
#
# # Node.js (Volta)
# export VOLTA_HOME="$HOME/.volta"
# _add_to_path_if_exists "$VOLTA_HOME/bin" "prepend"
#
# # Bun JavaScript runtime
# export BUN_INSTALL="$HOME/.bun"
# _add_to_path_if_exists "$BUN_INSTALL/bin" "prepend"
#
# # Additional Cloud CLIs (Outside Brew)
# _add_to_path_if_exists "$HOME/google-cloud-sdk/bin" "append"
#
# # Ruby
# if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
#   _add_to_path_if_exists "/opt/homebrew/opt/ruby/bin" "prepend"
#   _add_to_path_if_exists "`gem environment gemdir`/bin" "Prepend"
#   # export PATH=/opt/homebrew/opt/ruby/bin:$PATH
#   # export PATH=`gem environment gemdir`/bin:$PATH
# fi
# # _add_to_path_if_exists "$HOMEBREW_PREFIX/opt/ruby/bin"
# # _add_to_path_if_exists "$(gem environment gemdir)/bin"
# # if command -v gem &>/dev/null; then
# #   gem_bin="$(gem environment gemdir)/bin"
# #   _add_to_path_if_exists "$gem_bin"
# # fi
#
# ###############################
# # 6. Personal Scripts
# ###############################
# _add_to_path_if_exists "$HOME/.local/bin"
# # _add_to_path_if_exists "$HOME/bin"
#
# ###############################
# # Final pass to remove duplicates
# ###############################
# typeset -U PATH path
#
