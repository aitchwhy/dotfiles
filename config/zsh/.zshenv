# Environment variables that should be set for all shells

# XDG Base Directory specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Dotfiles location
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"

# Editor
export EDITOR="vim"
export VISUAL="$EDITOR"
[[ -n "$(command -v nvim)" ]] && export EDITOR="nvim" && export VISUAL="nvim"

# History
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=100000

# Go configuration
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"

# PATH configuration
typeset -U path
path=(
  "$HOME/.local/bin"
  "$HOME/bin"
  "$GOBIN"
  $path
)
export PATH

