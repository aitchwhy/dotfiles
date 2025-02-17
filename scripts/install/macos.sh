#!/usr/bin/env bash
# macOS system configuration

source "$(dirname "${BASH_SOURCE[0]}")/../utils/helpers.sh"
sourca

# System Preferences
configure_system() {
  header "Configuring macOS system preferences"

  # Finder
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true

  # Dock
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock show-recents -bool false
  defaults write com.apple.dock minimize-to-application -bool true

  # Keyboard
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

  # Screenshots
  mkdir -p "$HOME/Screenshots"
  defaults write com.apple.screencapture location -string "$HOME/Screenshots"
  defaults write com.apple.screencapture type -string "png"

  # Security
  defaults write com.apple.screensaver askForPassword -int 1
  defaults write com.apple.screensaver askForPasswordDelay -int 0

  success "System preferences configured"
}

# Restart affected applications
restart_apps() {
  header "Restarting affected applications"

  local apps=(
    "Finder"
    "Dock"
    "SystemUIServer"
  )

  for app in "${apps[@]}"; do
    killall "$app" >/dev/null 2>&1
  done

  success "Applications restarted"
}

# Main execution
main() {
  if ! is_macos; then
    error "This script is for macOS only"
    exit 1
  fi

  configure_system
  restart_apps
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
