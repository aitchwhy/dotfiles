#!/bin/sh
# Shell compatibility layer for Nix environments
# This file provides basic compatibility functions for both bash and zsh

# Detect shell type
if [ -n "$ZSH_VERSION" ]; then
  SHELL_TYPE="zsh"
elif [ -n "$BASH_VERSION" ]; then
  SHELL_TYPE="bash"
else
  SHELL_TYPE="sh"
fi

# Add to PATH safely (works in bash and zsh)
path_add() {
  if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
    export PATH="$1:$PATH"
    return 0
  fi
  return 1
}

# Check if a command exists (works in bash and zsh)
has_command() {
  command -v "$1" >/dev/null 2>&1
}

# Load Nix environment
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

# Export common environment variables
export EDITOR="nvim"
export VISUAL="$EDITOR"
export PAGER="less"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Add common paths
path_add "/usr/local/bin"
path_add "/opt/homebrew/bin"
path_add "$HOME/.nix-profile/bin"
path_add "/nix/var/nix/profiles/default/bin"

# Simple colored output that works in both bash and zsh
info() {
  printf "\033[0;34m[INFO]\033[0m %s\n" "$*"
}

success() {
  printf "\033[0;32m[SUCCESS]\033[0m %s\n" "$*"
}

warn() {
  printf "\033[0;33m[WARNING]\033[0m %s\n" "$*" >&2
}

error() {
  printf "\033[0;31m[ERROR]\033[0m %s\n" "$*" >&2
}

info "Loaded shell compatibility layer for $SHELL_TYPE shell"