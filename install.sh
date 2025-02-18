#!/usr/bin/env bash
# install.sh - Main installation script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

main() {
  info "Starting dotfiles installation..."

  # Create XDG directories
  ensure_dir "$XDG_CONFIG_HOME"
  ensure_dir "$XDG_CACHE_HOME"
  ensure_dir "$XDG_DATA_HOME"

  # Install Homebrew and packages
  ensure_homebrew
  brew_bundle

  # Setup ZSH
  setup_zsh

  # Link configuration files
  make_link "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
  make_link "$DOTFILES_DIR/vim" "$XDG_CONFIG_HOME/nvim"
  make_link "$DOTFILES_DIR/tmux" "$XDG_CONFIG_HOME/tmux"

  success "Dotfiles installation complete!"
}

main "$@"
