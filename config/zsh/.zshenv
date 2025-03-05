# Environment variables that should be set for all shells

################################################################################
# XDG Base Directory Specification
# - Reference: https://specifications.freedesktop.org/basedir-spec/latest/#basics
# - Cheat Sheet (https://gist.github.com/roalcantara/107ba66dfa3b9d023ac9329e639bc58c)
################################################################################
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
# export XDG_DATA_DIRS="???"
# export XDG_CONFIG_DIRS="???"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
# export XDG_RUNTIME_DIR="???"
export XDG_BIN_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export ZDOTDIR=${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}

# Dotfiles location
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"

export VOLTA_HOME="$HOME/.volta"
# export PATH="$VOLTA_HOME/bin:$PATH"

# . "$HOME/.cargo/env"

# Go
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"

# Python
export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc"
export PYTHONDONTWRITEBYTECODE=1 # Don't create .pyc files
# [[ -d "$HOME/.pyenv" ]] && {
#   export PYENV_ROOT="$HOME/.pyenv"
#   path=("$PYENV_ROOT/bin" $path)
#   eval "$(pyenv init --path)"
# }

# Node.js
# export NODE_REPL_HISTORY="$XDG_STATE_HOME/node_history"
# export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"

# uv docs - https://docs.astral.sh/uv/configuration/environment/

# Editor
export EDITOR="vim"
export VISUAL="$EDITOR"
# export PAGER="less -FRX"

# macOS specific

# brew https://docs.brew.sh/Manpage#environment
export HOMEBREW_NO_ANALYTICS=1 # Disable Homebrew analytics
export HOMEBREW_BAT=1          # Use bat for man pages
export HOMEBREW_CASK_OPTS="--appdir=${HOME}/Applications --fontdir=/Library/Fonts"

# Terminal
export COLORTERM=truecolor
export TERM_PROGRAM="${TERM_PROGRAM:-Apple_Terminal}"
