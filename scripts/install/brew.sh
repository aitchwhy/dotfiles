#!/usr/bin/env bash
# Homebrew installation and package management

source "$(dirname "${BASH_SOURCE[0]}")/../utils/helpers.sh"

# Install Homebrew if not present
install_homebrew() {
  if ! has_command brew; then
    header "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if is_apple_silicon; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi

  success "Homebrew installed"
}

# Install packages from Brewfile
install_packages() {
  header "Installing Homebrew packages"

  if [[ ! -f "$HOME/.Brewfile" ]]; then
    error "Brewfile not found at $HOME/.Brewfile"
    return 1
  fi

  # Update Homebrew
  brew update

  # Install from Brewfile
  brew bundle --global

  # Cleanup
  brew cleanup --prune=all

  success "Homebrew packages installed"
}

# Main execution
main() {
  install_homebrew
  install_packages
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
