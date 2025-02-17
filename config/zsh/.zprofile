
# -----------------------------------------------------------------------------
# ~/.zshenv (???)
# -----------------------------------------------------------------------------


# Initialize Homebrew
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Ensure path arrays do not contain duplicates.
typeset -gU path fpath

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


# XDG Base Directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Ensure directories exist
mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"

# Core paths
export DOTFILES="$HOME/dotfiles"
export CONFIGS="$XDG_CONFIG_HOME"

# Tool configuration paths
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
export STARSHIP_CACHE="$XDG_CACHE_HOME/starship"
export ATUIN_CONFIG_DIR="$XDG_CONFIG_HOME/atuin"
export ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij"
export BAT_CONFIG_PATH="$XDG_CONFIG_HOME/bat/config"
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"

# Editor configurations
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="bat"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Language configurations
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# History configuration
export HISTFILE="$ZDOTDIR/history"
export HISTSIZE=1000000
export SAVEHIST=1000000
export _ZO_DATA_DIR="$XDG_DATA_HOME/zoxide"


# Go configuration
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
# Homebrew configuration
# export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_AUTOREMOVE=1
export HOMEBREW_NO_BOTTLE_SOURCE_FALLBACK=1
# export HOMEBREW_NO_INSTALL_CLEANUP=1
export HOMEBREW_BUNDLE_FILE="$HOME/.Brewfile"

export VOLTA_HOME="$HOME/.volta"


# # Additional tool configurations
# export NODE_REPL_HISTORY="$XDG_STATE_HOME/node/repl_history"
# export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/startup.py"
# export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
# export AWS_CONFIG_FILE="$XDG_CONFIG_HOME/aws/config"
# export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME/aws/credentials"

########

_add_to_path_if_exists "$HOME/.local/bin" "prepend"

# Ruby configuration
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
    _add_to_path_if_exists "/opt/homebrew/opt/ruby/bin" "prepend"
    _add_to_path_if_exists "$(gem environment gemdir)/bin" "prepend"
fi


# Node.js management with volta
# _add_to_path_if_exists "$VOLTA_HOME/bin" "prepend"


# Ensure path arrays do not contain duplicates.
typeset -gU path fpath
# Set up PATH (Path Configuration)
# https://mac.install.guide/terminal/path
# typeset -U PATH path
# path=(
#     $HOME/local/bin
#     $HOME/{bin,sbin}
#     $HOME/{bin,sbin}
#     /opt/homebrew/bin
#     /opt/homebrew/sbin
#     $path
# )
# export PATH
# Core paths

_add_to_path_if_exists "$GOBIN"

# Rust toolchain
_add_to_path_if_exists "$HOME/.cargo/bin"


# Ensure path arrays do not contain duplicates.
typeset -gU path fpath

# # ============================================================================ #
# # XDG
# # ============================================================================ #
# XDG Base Directory
# export XDG_CONFIG_HOME="$HOME/.config"
# export XDG_CACHE_HOME="$HOME/.cache"
# export XDG_DATA_HOME="$HOME/.local/share"
# export XDG_STATE_HOME="$HOME/.local/state"



# # Python - use uv for better performance
# export UV_SYSTEM_PYTHON="/opt/homebrew/bin/python3"
# _add_to_path_if_exists "$HOME/.local/bin" "prepend"

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
