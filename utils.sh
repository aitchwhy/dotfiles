#!/usr/bin/env bash
# utils.sh - Core utilities for dotfiles management

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
