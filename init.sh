#!/usr/bin/env bash
# init.sh
# Bootstrap script for macOS 15.3.1+ (Sequoia) Apple Silicon
# Sets up symlinks, environment variables, etc.

set -euo pipefail

# Configuration
# DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# DOTFILES="$HOME/dotfiles"
# CONFIG="$HOME/.config"
# XDG_STATE_HOME="$HOME/.local/state"
# XDG_DATA_HOME="$HOME/.local/share"
# ZDOTDIR="$HOME/.config/zsh"

# export XDG_CONFIG_HOME="$HOME/.config"
# export XDG_CACHE_HOME="$HOME/.cache"
# export XDG_DATA_HOME="$HOME/.local/share"
# export XDG_STATE_HOME="$HOME/.local/state"
# export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

ZSH_CONFIG_DIR="${HOME}/.config/zsh"
DOTFILES="$HOME/dotfiles"
ZSHENV_FILE="${HOME}/.zshenv"

# Clean .DS_Store files
clean_ds_store() {
  log "Cleaning .DS_Store files..."
  find "$DOTFILES" -name ".DS_Store" -delete
}

# Utility functions
log() { echo "==> $*" >&2; }
error() {
  echo "ERROR: $*" >&2
  exit 1
}

setup_xcode_clt() {
  ### 1. Detect and install Xcode Command Line Tools if missing ###
  echo "Checking for Xcode Command Line Tools..."
  if ! xcode-select -p &>/dev/null; then
    echo "Xcode Command Line Tools not found. Installing..."
    xcode-select --install
    # The CLI tools installer will prompt the user to complete installation
    # so we can exit after the prompt to avoid continuing prematurely.
    echo "Please rerun this script after Xcode Command Line Tools finish installing."
    exit 1
  fi
  echo "Xcode Command Line Tools are installed."
}

# Install Homebrew and packages
setup_homebrew() {
  ### 2. (Optional) Check and install Homebrew ###
  if ! command -v brew &>/dev/null; then
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # After installation, you typically need to add brew to PATH. This is done automatically on recent macOS,
    # but double-check the output from the installer for next steps.
  fi
  echo "Homebrew is installed (or was already present)."
}

# Configure zshenv (2 files - ~/.zshenv and $DOTFILES/config/zsh/.zshenv)
setup_zsh() {
  ### 3. Create ~/.config/zsh directory ###
  if [[ ! -d "$ZSH_CONFIG_DIR" ]]; then
    echo "Creating directory: $ZSH_CONFIG_DIR"
    mkdir -p "$ZSH_CONFIG_DIR"
  else
    echo "Directory already exists: $ZSH_CONFIG_DIR"
  fi

  ### 4. Configure ZDOTDIR in ~/.zshenv ###
  if grep -q 'export ZDOTDIR=' "$ZSHENV_FILE" 2>/dev/null; then
    echo "ZDOTDIR already set in $ZSHENV_FILE. Skipping..."
  else
    echo "Setting ZDOTDIR in $ZSHENV_FILE"
    echo "export ZDOTDIR=\"\$HOME/.config/zsh\"" >>"$ZSHENV_FILE"
  fi
}

# Configure macOS defaults
setup_macos() {
  log "Configuring macOS defaults..."

  source "$DOTFILES/scripts/macos-defaults.sh"

  # Restart affected applications
  for app in "Finder" "Dock"; do
    killall "${app}" &>/dev/null || true
  done
}

# Main installation
main() {
  log "Starting dotfiles installation..."

  clean_ds_store
  setup_zsh
  source "$DOTFILES/scripts/symlinks.sh"
  setup_homebrew
  # setup_git
  # setup_macos

  log "Installation complete! Please restart your shell and Finder."
  log "Your old configurations have been backed up to ~/.dotfiles_backup if they existed."
}

main "$@"
