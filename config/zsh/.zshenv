# ========================================================================
# ZSH Environment (.zshenv)
# ========================================================================
# Environment variables for all shells (login, interactive, scripts)
# This is the first file loaded by zsh
# References:
# - https://wiki.archlinux.org/title/Zsh#Configuration_files
# - https://specifications.freedesktop.org/basedir-spec/latest/#basics

# ========================================================================
# XDG Base Directory Specification
# ========================================================================
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"

# Ensure XDG directories exist
if [[ ! -d "$XDG_CONFIG_HOME" ]]; then mkdir -p "$XDG_CONFIG_HOME"; fi
if [[ ! -d "$XDG_CACHE_HOME" ]]; then mkdir -p "$XDG_CACHE_HOME"; fi
if [[ ! -d "$XDG_DATA_HOME" ]]; then mkdir -p "$XDG_DATA_HOME"; fi
if [[ ! -d "$XDG_STATE_HOME" ]]; then mkdir -p "$XDG_STATE_HOME"; fi

# Ensure ZSH config directory is set
export ZDOTDIR=${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}

# Dotfiles location
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
