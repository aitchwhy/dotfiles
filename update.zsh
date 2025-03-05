#!/usr/bin/env zsh

# ========================================================================
# update.zsh - macOS dotfiles update script
# ========================================================================

set -euo pipefail

# ========================================================================
# Environment Configuration
# ========================================================================
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Source utilities and configurations
# source "$DOTFILES/utils.zsh"
# source "$DOTFILES/config/zsh/functions.zsh"
# source "$DOTFILES/config/zsh/symlinks.zsh"

# ========================================================================
# Update Functions
# ========================================================================
update_dotfiles() {
  info "Updating dotfiles repository..."
  cd "$DOTFILES"
  git pull origin main
}

update_homebrew() {
  info "Updating Homebrew..."
  brew update
  brew upgrade

  if [[ -f "$DOTFILES/Brewfile" ]]; then
    info "Updating Homebrew packages from Brewfile..."
    brew bundle install --verbose --global --all --no-lock --cleanup --force
  fi
}

update_symlinks() {
  info "Updating symlinks..."

  # First, remove all existing symlinks and files that we'll be managing
  info "Cleaning up existing configurations..."
  for key in ${(k)DOTFILES_TO_SYMLINK_MAP}; do
    local dst="${DOTFILES_TO_SYMLINK_MAP[$key]}"

    # Remove existing symlink or file/directory
    if [[ -L "$dst" || -e "$dst" ]]; then
      rm -rf "$dst"
      success "Removed existing: $dst"
    fi
  done

  # Now create fresh symlinks
  info "Creating new symlinks..."
  for key in ${(k)DOTFILES_TO_SYMLINK_MAP}; do
    local src="$key"
    local dst="${DOTFILES_TO_SYMLINK_MAP[$key]}"
    local parent_dir=$(dirname "$dst")

    # Create parent directory if it doesn't exist
    ensure_dir "$parent_dir"

    # Create the symlink
    if [[ -e "$src" ]]; then
      ln -sf "$src" "$dst"
      success "Symlinked $dst -> $src source file"
    else
      warn "Source '$src' does not exist, skipping"
    fi
  done
}

update_macos_preferences() {
  info "Updating macOS preferences..."

  # Faster key repeat
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 15

  # Disable press-and-hold for keys in favor of key repeat
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

  # Always show file extensions
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true

  # Don't write .DS_Store files on network drives
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

  # Dock settings
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock show-recents -bool false

  # Enable trackpad tap to click
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

  # Finder settings
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder _FXSortFoldersFirst -bool true

  # Restart affected applications
  for app in "Finder" "Dock"; do
    killall "$app" &>/dev/null || true
  done
}

refresh_shell() {
  info "Refreshing shell configuration..."
  exec zsh
}

# ========================================================================
# Main Function
# ========================================================================
main() {
  info "Starting dotfiles update..."

  # Update components
  update_dotfiles
  update_homebrew
  update_symlinks
  update_macos_preferences

  success "Update complete! 🎉"
  info "Refreshing shell to apply changes..."
  refresh_shell
}

# Run the script
main "$@"
