#!/usr/bin/env bash
# utils.sh - Core shell utilities for dotfiles management

# -----------------------------------------------------------------------------
# Logging utilities
# -----------------------------------------------------------------------------
log() { printf "%b\n" "$*" >&2; }
info() { log "\033[34m[INFO]\033[0m $*"; }
warn() { log "\033[33m[WARN]\033[0m $*"; }
error() { log "\033[31m[ERROR]\033[0m $*"; }
success() { log "\033[32m[OK]\033[0m $*"; }

# -----------------------------------------------------------------------------
# System detection
# -----------------------------------------------------------------------------
is_macos() { [[ "$OSTYPE" == darwin* ]]; }
is_apple_silicon() { [[ "$(uname -m)" == "arm64" ]]; }
has_command() { command -v "$1" >/dev/null 2>&1; }

# -----------------------------------------------------------------------------
# File operations
# -----------------------------------------------------------------------------
# Create backup directory
ensure_backup_dir() {
  if [[ ! -d "$BACKUP_DIR" ]]; then
    info "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
  fi
}

# Back up a file or directory with timestamp
backup_file() {
  local file="$1"
  
  if [[ ! -e "$file" ]]; then
    return 0  # File doesn't exist, nothing to backup
  fi
  
  ensure_backup_dir
  
  # Create the relative path structure in the backup dir
  local rel_path="${file#$HOME/}"
  local backup_path="$BACKUP_DIR/$rel_path"
  local backup_dir="$(dirname "$backup_path")"
  
  if [[ ! -d "$backup_dir" ]]; then
    mkdir -p "$backup_dir"
  fi
  
  info "Backing up $file to $backup_path"
  cp -R "$file" "$backup_path"
  return 0
}

# Create a symlink with proper error handling
make_link() {
  local src_orig="$1"
  local dst_symlink="$2"

  if [[ ! -e "$src_orig" ]]; then
    error "Source does not exist: $src_orig"
    return 1
  fi

  # Create parent directory if it doesn't exist
  local dst_dir=$(dirname "$dst_symlink")
  if [[ ! -d "$dst_dir" ]]; then
    info "Creating directory: $dst_dir"
    mkdir -p "$dst_dir"
  fi

  # Check if destination already exists and handle it
  if [[ -e "$dst_symlink" || -L "$dst_symlink" ]]; then
    # If it's already linked to the right place, skip
    if [[ -L "$dst_symlink" && "$(readlink "$dst_symlink")" == "$src_orig" ]]; then
      info "Link already exists: $dst_symlink → $src_orig"
      return 0
    fi
    # Otherwise backup and remove
    backup_file "$dst_symlink"
    rm -f "$dst_symlink"
  fi
  
  info "Linking $src_orig → $dst_symlink"
  ln -sf "$src_orig" "$dst_symlink"
  success "Created link: $dst_symlink → $src_orig"
}

# Ensure a directory exists
ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    info "Creating directory: $dir"
    mkdir -p "$dir"
  fi
}

# -----------------------------------------------------------------------------
# Path management
# -----------------------------------------------------------------------------
# Add directory to PATH if it exists and isn't already there
_add_to_path_if_exists() {
  local dir="$1"
  local position="${2:-append}"
  [[ -d "$dir" ]] || return
  [[ ":$PATH:" == *":$dir:"* ]] && return
  if [[ "$position" == "prepend" ]]; then
    path=("$dir" "${path[@]}")
  else
    path+=("$dir")
  fi
}

# -----------------------------------------------------------------------------
# Git utilities
# -----------------------------------------------------------------------------
# Get the root directory of a git repository
get_repo_root() {
  git -C "${1:-$PWD}" rev-parse --show-toplevel 2>/dev/null
}

# Check if a directory is inside a git repository
is_git_repo() {
  git -C "${1:-$PWD}" rev-parse --is-inside-work-tree &>/dev/null
}

# -----------------------------------------------------------------------------
# Utility functions
# -----------------------------------------------------------------------------
# Check if directory exists and is not empty
is_dir_populated() {
  [[ -d "$1" && "$(ls -A "$1" 2>/dev/null)" ]]
}

# Get absolute path to a file or directory
get_abs_path() {
  local path="$1"
  echo "$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"
}

# Clean .DS_Store files
clean_ds_store() {
  local dir="${1:-$PWD}"
  find "$dir" -name ".DS_Store" -delete
}
