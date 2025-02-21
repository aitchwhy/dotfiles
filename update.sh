#!/usr/bin/env bash
# Update script to manage dotfiles symlinks

set -euo pipefail

# Core paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
DOTFILES="${DOTFILES:-$HOME/dotfiles}"

# Logging utilities
log() { printf "%b\n" "$*" >&2; }
info() { log "\\033[34m[INFO]\\033[0m $*"; }
warn() { log "\\033[33m[WARN]\\033[0m $*"; }
error() { log "\\033[31m[ERROR]\\033[0m $*"; }
success() { log "\\033[32m[OK]\\033[0m $*"; }

# Create directory if it doesn't exist
ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    info "Creating directory: $dir"
    mkdir -p "$dir"
  fi
}

# Create symlink with backup
make_link() {
  local src="$1"
  local dst="$2"

  if [[ ! -e "$src" ]]; then
    error "Source does not exist: $src"
    return 1
  fi

  if [[ -e "$dst" ]] && [[ ! -L "$dst" ]]; then
    local backup="${dst}.backup-$(date +%Y%m%d_%H%M%S)"
    info "Backing up $dst to $backup"
    mv "$dst" "$backup"
  fi

  info "Linking $src → $dst"
  ln -sf "$src" "$dst"
}

clean_symlinks() {
  info "Cleaning existing symlinks in $XDG_CONFIG_HOME"

  # Find all symlinks in XDG_CONFIG_HOME
  find "$XDG_CONFIG_HOME" -type l | while read -r link; do
    if [[ ! -e "$link" ]]; then
      warn "Removing dead symlink: $link"
      rm "$link"
    fi
  done
}

create_config_symlinks() {
  info "Creating symlinks from $DOTFILES/config"

  # Handle standard config files
  cd "$DOTFILES/config" || exit 1
  find . -type f -not -path '*/\.*' | while read -r file; do
    local rel_path="${file#./}"
    local target_dir="$(dirname "$XDG_CONFIG_HOME/$rel_path")"

    ensure_dir "$target_dir"
    make_link "$DOTFILES/config/$rel_path" "$XDG_CONFIG_HOME/$rel_path"
  done
}

setup_macos_specific() {
  if [[ "$OSTYPE" == darwin* ]]; then
    info "Setting up macOS-specific configurations"

    # Create required directories
    ensure_dir "$HOME/.hammerspoon"
    ensure_dir "$HOME/Library/Application Support/Code/User"
    ensure_dir "$HOME/Library/Application Support/Cursor/User"

    # Link macOS-specific configs
    make_link "$DOTFILES/config/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"
    make_link "$DOTFILES/config/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
    make_link "$DOTFILES/config/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
    make_link "$DOTFILES/config/cursor/settings.json" "$HOME/Library/Application Support/Cursor/User/settings.json"
    make_link "$DOTFILES/config/cursor/keybindings.json" "$HOME/Library/Application Support/Cursor/User/keybindings.json"
  fi
}

main() {
  info "Starting dotfiles update..."

  # Ensure XDG directories exist
  ensure_dir "$XDG_CONFIG_HOME"
  ensure_dir "$XDG_CACHE_HOME"
  ensure_dir "$XDG_DATA_HOME"
  ensure_dir "$XDG_STATE_HOME"

  # Clean and update symlinks
  clean_symlinks
  create_config_symlinks
  setup_macos_specific

  success "Dotfiles update complete!"
}

main "$@"
