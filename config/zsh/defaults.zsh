#!/usr/bin/env zsh
#
echo "macos defaults"


# function setup_macos_preferences() {
#   info "Configuring macOS system preferences..."
#   
#   # Faster key repeat
#   defaults write NSGlobalDomain KeyRepeat -int 2
#   defaults write NSGlobalDomain InitialKeyRepeat -int 15
#   
#   # Disable press-and-hold for keys in favor of key repeat
#   defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
#   
#   # Always show file extensions
#   defaults write NSGlobalDomain AppleShowAllExtensions -bool true
#   
#   # Don't write .DS_Store files on network drives
#   defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
#   
#   # Dock settings
#   defaults write com.apple.dock autohide -bool true
#   defaults write com.apple.dock autohide-delay -float 0
#   defaults write com.apple.dock show-recents -bool false
#   
#   # Enable trackpad tap to click
#   defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
#   
#   # Finder settings
#   defaults write com.apple.finder AppleShowAllFiles -bool true
#   defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
#   defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
#   defaults write com.apple.finder ShowPathbar -bool true
#   defaults write com.apple.finder ShowStatusBar -bool true
#   defaults write com.apple.finder _FXSortFoldersFirst -bool true
#   
#   # Restart affected applications
#   for app in "Finder" "Dock"; do
#     killall "$app" &>/dev/null || true
#   done
#   
#   success "macOS preferences configured"
# }



