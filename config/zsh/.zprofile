# -----------------------------------------------------------------------------
# ~/.zprofile (Invoked once at login on macOS)
#
# mac.install.guide tips (https://mac.install.guide/terminal/zshrc-zprofile)
# - Use ~/.zprofile to set the PATH and EDITOR environment variables.
# -----------------------------------------------------------------------------

# Environment variables that should be set for all shells
# XDG Base Directory specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export ZDOTDIR=${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}

# Dotfiles location
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"

# Editor
export EDITOR="vim"
export VISUAL="$EDITOR"

# History
# export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=100000

# PATH configuration
eval "$(/opt/homebrew/bin/brew shellenv)"

# Remove duplicate paths
# typeset -U path PATH
# path=(
#   "$HOME/.local/bin"
#   "$HOME/bin"
#   $path
# )

# export PATH
