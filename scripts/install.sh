#!/bin/zsh
# Dotfiles installer for macOS

# Create symlinks for config files
ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/dotfiles/config/starship.toml ~/.config/starship.toml
ln -snf ~/dotfiles/config/nvim ~/.config/nvim

# Install Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
  xcode-select --install
fi

# Install Homebrew
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install packages from Brewfile
brew bundle --file=~/dotfiles/Brewfile

# Setup project directories
~/dotfiles/scripts/setup_project_dirs.sh