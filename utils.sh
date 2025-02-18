#!/usr/bin/env bash
# utils.sh - Core shell utilities for dotfiles management

# Strict error handling
set -euo pipefail

# -----------------------------------------------------------------------------
# Environment setup
# -----------------------------------------------------------------------------
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
export ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"

# -----------------------------------------------------------------------------
# Logging utilities
# -----------------------------------------------------------------------------
log() { printf "%b\n" "$*" >&2; }
info() { log "\\033[34m[INFO]\\033[0m $*"; }
warn() { log "\\033[33m[WARN]\\033[0m $*"; }
error() { log "\\033[31m[ERROR]\\033[0m $*"; }
success() { log "\\033[32m[OK]\\033[0m $*"; }

# -----------------------------------------------------------------------------
# System detection
# -----------------------------------------------------------------------------
is_macos() { [[ "$OSTYPE" == darwin* ]]; }
is_apple_silicon() { [[ "$(uname -m)" == "arm64" ]]; }
has_command() { command -v "$1" >/dev/null 2>&1; }

# -----------------------------------------------------------------------------
# File operations
# -----------------------------------------------------------------------------
backup_file() {
  local file="$1"
  local backup="${file}.backup-$(date +%Y%m%d_%H%M%S)"

  if [[ -e "$file" ]]; then
    info "Backing up $file to $backup"
    mv "$file" "$backup"
  fi
}

make_link() {
  local src="$1"
  local dst="$2"

  if [[ ! -e "$src" ]]; then
    error "Source does not exist: $src"
    return 1
  fi

  backup_file "$dst"
  info "Linking $src → $dst"
  ln -sf "$src" "$dst"
}

ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    info "Creating directory: $dir"
    mkdir -p "$dir"
  fi
}

# -----------------------------------------------------------------------------
# Package management
# -----------------------------------------------------------------------------
ensure_homebrew() {

  # if ! has_command brew; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if is_apple_silicon; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
}

brew_bundle() {
  local brewfile="${1:-$DOTFILES_DIR/Brewfile}"
  if [[ -f "$brewfile" ]]; then
    info "Installing Homebrew packages from $brewfile"
    brew bundle install --force --verbose --zap --file="$brewfile"
  fi
}

# -----------------------------------------------------------------------------
# ZSH setup
# -----------------------------------------------------------------------------

setup_zshenv() {
  if [[ ! -f "$HOME/.zshenv" ]]; then
    log "Configuring $HOME/.zshenv..."

    cat >"$HOME/.zshenv" <<EOF
# Minimal stub for Zsh to load configs from ~/.config/zsh
export ZDOTDIR="$HOME/.config/zsh"
[[ -f "$ZDOTDIR/.zshenv.local" ]] && source "$ZDOTDIR/.zshenv.local"
EOF
  fi
}

setup_zsh() {
  ensure_dir "$ZDOTDIR"
  setup_zshenv
  make_link "$ZDOTDIR/.zshrc" "$ZDOTDIR/.zshrc"
  make_link "$ZDOTDIR/.zprofile" "$ZDOTDIR/.zprofile"
}

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

######################
# Finds the top-level Git repository directory for a given file/directory path.
# Usage: get_repo_root [path]
#        If no path is provided, defaults to $0 (the calling script).
#
# Call the function to get the repo root of this script's location
###################### Usage example
# #!/bin/sh
# some_script.sh
#
# # Source the utilities
# . /path/to/git_utils.sh
#
# # Call the function to get the repo root of this script's location
# root_dir=$(get_repo_root "$0")
# echo "Repository root: $root_dir"
#
# (optionally, pass a different path (e.g., a subdirectory) instead of $0 if needed
#
# other_root=$(get_repo_root "/some/other/path")
# echo "Repository root for that path: $other_root"
######################

get_repo_root() {
  git -C "${1:-$PWD}" rev-parse --show-toplevel 2>/dev/null
}

# get_repo_root() {
#   file="${1:-$0}"

#   # Save the current directory to restore later
#   saved_pwd=$(pwd)

#   # cd to the directory of the provided path (resolving any symlinks if possible)
#   script_dir=$(CDPATH= cd -- "$(dirname -- "$file")" && pwd -P) || {
#     printf "Error: Failed to cd into '%s'\n" "$file" >&2
#     return 1
#   }

#   cd "$script_dir" || {
#     printf "Error: Cannot cd to script directory '%s'\n" "$script_dir" >&2
#     return 1
#   }

#   # Obtain the top-level Git directory; exit non-zero on failure
#   repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
#     printf "Error: '%s' is not in a Git repository.\n" "$script_dir" >&2
#     cd "$saved_pwd" || exit 1
#     return 1
#   }

#   # Return to original directory
#   cd "$saved_pwd" || exit 1

#   # Output the Git root
#   printf "%s\n" "$repo_root"
# }
