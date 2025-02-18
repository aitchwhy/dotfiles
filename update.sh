#!/usr/bin/env bash
# update.sh - Script for updating dotfiles

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils.sh"

main() {
  info "Updating dotfiles..."

  # Pull latest changes
  cd "$DOTFILES_DIR"
  git pull origin main

  # Update Homebrew packages
  if has_command brew; then
    info "Updating Homebrew packages..."
    brew update
    brew upgrade
    brew cleanup
  fi

  # Relink configuration files
  setup_zsh

  success "Dotfiles update complete!"
}

main "$@"
