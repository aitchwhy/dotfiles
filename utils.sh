#!/usr/bin/env zsh

# ========================================================================
# utils.sh - Utility functions for dotfiles installation and management
# ========================================================================

# ========================================================================
# Terminal Colors
# ========================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# ========================================================================
# Logging Functions
# ========================================================================
function info() {
  printf "${BLUE}[INFO]${RESET} %s\n" "$*"
}

function success() {
  printf "${GREEN}[SUCCESS]${RESET} %s\n" "$*"
}

function warn() {
  printf "${YELLOW}[WARNING]${RESET} %s\n" "$*" >&2
}

function error() {
  printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2
}

# ========================================================================
# System Detection
# ========================================================================
function is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

function is_apple_silicon() {
  [[ "$(uname -m)" == "arm64" ]]
}

function has_command() {
  command -v "$1" &>/dev/null
}

# ========================================================================
# File & Directory Operations
# ========================================================================
function ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    success "Created directory: $dir"
  fi
}

function backup_file() {
  local file="$1"

  if [[ ! -e "$file" && ! -L "$file" ]]; then
    # Nothing to back up
    return 0
  fi

  ensure_dir "$BACKUP_DIR"

  # Create subdirectories in backup to maintain structure
  local relative_path
  relative_path=$(echo "$file" | sed "s|^$HOME/||")
  local backup_subdir="$BACKUP_DIR/$(dirname "$relative_path")"

  ensure_dir "$backup_subdir"

  # Copy the file or directory to backup location
  cp -R "$file" "$backup_subdir/"
  success "Backed up $file to $backup_subdir/"
}

function make_link() {
  local src="$1"
  local dst="$2"

  # Source must exist
  if [[ ! -e "$src" ]]; then
    error "Source doesn't exist: $src"
    return 1
  fi

  # If destination exists, back it up
  if [[ -e "$dst" || -L "$dst" ]]; then
    backup_file "$dst"
    rm -rf "$dst"
  fi

  # Create parent directory if it doesn't exist
  ensure_dir "$(dirname "$dst")"

  # Create the symlink
  ln -sf "$src" "$dst"
  success "Linked $src -> $dst"
}

# ========================================================================
# Process Management
# ========================================================================
function kill_process() {
  local process="$1"
  if pgrep -x "$process" >/dev/null; then
    pkill -x "$process"
    success "Killed $process"
  fi
}

# ========================================================================
# Homebrew Helpers
# ========================================================================
function brew_install() {
  if ! has_command brew; then
    error "Homebrew not installed"
    return 1
  fi

  local pkg="$1"
  if brew list "$pkg" &>/dev/null; then
    info "Package already installed: $pkg"
  else
    brew install "$pkg"
    success "Installed $pkg"
  fi
}

function brew_cask_install() {
  if ! has_command brew; then
    error "Homebrew not installed"
    return 1
  fi

  local cask="$1"
  if brew list --cask "$cask" &>/dev/null; then
    info "Cask already installed: $cask"
  else
    brew install --cask "$cask"
    success "Installed cask: $cask"
  fi
}
