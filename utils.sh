#!/usr/bin/env bash
# utils.sh - Core shell utilities for dotfiles management
# POSIX-compliant, works with sh/bash/zsh
#
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
  if ! has_command brew; then
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
    brew bundle --file="$brewfile"
  fi
}

# -----------------------------------------------------------------------------
# ZSH setup
# -----------------------------------------------------------------------------
setup_zsh() {
  ensure_dir "$ZDOTDIR"
  make_link "$DOTFILES_DIR/zsh/.zshenv" "$HOME/.zshenv"
  make_link "$DOTFILES_DIR/zsh/.zshrc" "$ZDOTDIR/.zshrc"

  # Change shell to zsh if needed
  if [[ "$SHELL" != *"zsh" ]]; then
    local zsh_path="$(command -v zsh)"
    if [[ -z "$zsh_path" ]]; then
      error "ZSH not found"
      return 1
    fi
    info "Changing shell to ZSH"
    chsh -s "$zsh_path"
  fi
}

##############

# Core environment setup
setup_core_env() {
  # Core paths
  DOTFILES="${DOTFILES:-$HOME/dotfiles}"
  XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
  XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
  XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
  XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
  ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"
  BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

  # Export all variables
  export DOTFILES XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME ZDOTDIR BACKUP_DIR

  # Create essential directories
  for dir in "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$ZDOTDIR"; do
    ensure_dir "$dir"
  done
}

# ANSI colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Logging functions
log() { printf "${BLUE}==>${NC} %s\n" "$*"; }
success() { printf "${GREEN}✓${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}!${NC} %s\n" "$*"; }
error() { printf "${RED}✗${NC} %s\n" "$*" >&2; }
header() { printf "\n${BOLD}%s${NC}\n" "$*"; }

# System detection
is_macos() { [ "$(uname)" = "Darwin" ]; }
is_arm64() { [ "$(uname -m)" = "arm64" ]; }
is_apple_silicon() { is_macos && is_arm64; }

# Command and file operations
command_exists() { command -v "$1" >/dev/null 2>&1; }
ensure_dir() { [ -d "$1" ] || mkdir -p "$1"; }
ensure_file() { [ -f "$1" ] || touch "$1"; }

# Backup functionality
backup_file() {
  local file="$1"
  if [ -e "$file" ]; then
    local backup="$BACKUP_DIR/$(basename "$file")"
    ensure_dir "$(dirname "$backup")"
    mv "$file" "$backup"
    success "Backed up: $file → $backup"
  fi
}

# File operations
safe_remove() {
  local target="$1"
  if [ -e "$target" ]; then
    backup_file "$target"
    rm -rf "$target"
    success "Removed: $target"
  fi
}

# Symlink management
create_symlink() {
  local src="$1"
  local dest="$2"
  local force="${3:-false}"

  # Validate source exists
  if [ ! -e "$src" ]; then
    error "Source doesn't exist: $src"
    return 1
  fi

  # Create parent directory if needed
  ensure_dir "$(dirname "$dest")"

  # Handle existing destination
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
      success "Already linked: $dest → $src"
      return 0
    fi

    if [ "$force" = "true" ]; then
      safe_remove "$dest"
    else
      warn "File exists: $dest"
      printf "Replace? [y/N] "
      read -r reply
      case "$reply" in
      [Yy]*) safe_remove "$dest" ;;
      *)
        warn "Skipping: $dest"
        return 0
        ;;
      esac
    fi
  fi

  # Create symlink
  ln -sf "$src" "$dest"
  success "Linked: $dest → $src"
}

# Path management
prepend_path() {
  [ -d "$1" ] || return 1
  case ":$PATH:" in
  *":$1:"*) return 1 ;;
  *) export PATH="$1:$PATH" ;;
  esac
}

append_path() {
  [ -d "$1" ] || return 1
  case ":$PATH:" in
  *":$1:"*) return 1 ;;
  *) export PATH="$PATH:$1" ;;
  esac
}

# Clean broken symlinks
clean_broken_links() {
  local dir="$1"
  if [ -d "$dir" ]; then
    find "$dir" -type l ! -exec test -e {} \; -delete
    success "Cleaned broken links in: $dir"
  fi
}

# macOS specific utilities
setup_macos_paths() {
  if is_macos; then
    for path in \
      "/opt/homebrew/bin" \
      "/opt/homebrew/sbin" \
      "/usr/local/bin" \
      "/usr/local/sbin" \
      "$HOME/.local/bin"; do
      prepend_path "$path"
    done
  fi
}

# Initialize environment
init_env() {
  setup_core_env
  setup_macos_paths
}
#
# ########
#
# #!/bin/sh
# # Core shell utilities for dotfiles management
# # Compatible with POSIX shell, zsh, and bash
#
# # Core environment setup
# setup_core_env() {
#     DOTFILES="${DOTFILES:-$HOME/dotfiles}"
#     XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
#     XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
#     XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
#     XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
#     ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"
#     BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
#     export DOTFILES XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME ZDOTDIR
# }
#
# # ANSI colors
# RED='\033[0;31m'
# GREEN='\033[0;32m'
# YELLOW='\033[0;33m'
# BLUE='\033[0;34m'
# BOLD='\033[1m'
# NC='\033[0m'
#
# # Logging functions
# log() { echo -e "${BLUE}==>${NC} $*"; }
# success() { echo -e "${GREEN}✓${NC} $*"; }
# warn() { echo -e "${YELLOW}!${NC} $*"; }
# error() { echo -e "${RED}✗${NC} $*" >&2; }
# header() { echo -e "\n${BOLD}$*${NC}"; }
#
# # System detection
# is_macos() { [ "$(uname)" = "Darwin" ]; }
# is_arm64() { [ "$(uname -m)" = "arm64" ]; }
# is_apple_silicon() { is_macos && is_arm64; }
#
# # Command and directory handling
# command_exists() { command -v "$1" >/dev/null 2>&1; }
# ensure_dir() { [ -d "$1" ] || mkdir -p "$1"; }
#
# # File operations
# backup_file() {
#     local file="$1"
#     if [ -e "$file" ]; then
#         local backup="$file.backup-$(date +%Y%m%d-%H%M%S)"
#         mkdir -p "$(dirname "$backup")"
#         mv "$file" "$backup"
#         success "Backed up: $file → $backup"
#     fi
# }
#
# # Path management
# prepend_path() {
#     [ -d "$1" ] || return 1
#     case ":$PATH:" in
#         *":$1:"*) return 1 ;;
#         *) export PATH="$1:$PATH" ;;
#     esac
# }
#
# # XDG directory setup
# setup_xdg_dirs() {
#     for dir in \
#         "$XDG_CONFIG_HOME" \
#         "$XDG_CACHE_HOME" \
#         "$XDG_DATA_HOME" \
#         "$XDG_STATE_HOME" \
#         "$ZDOTDIR"
#     do
#         ensure_dir "$dir"
#     done
# }
#
# # Initialize core environment
# init_core_env() {
#     setup_core_env
#     setup_xdg_dirs
#
#     if is_macos; then
#         for path in \
#             "/opt/homebrew/bin" \
#             "/opt/homebrew/sbin" \
#             "/usr/local/bin" \
#             "/usr/local/sbin" \
#             "$HOME/.local/bin"
#         do
#             prepend_path "$path"
#         done
#     fi
# }
