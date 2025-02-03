#!/usr/bin/env zsh
# Unified ZSH configuration
set -e

# Create essential symlinks
ln -sf ~/dotfiles/.zshrc ~/.zshrc
ln -sf ~/dotfiles/Brewfile ~/Brewfile
ln -sf ~/dotfiles/starship.toml ~/.config/starship.toml
ln -snf ~/dotfiles/nvim ~/.config/nvim

# Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install
fi

# Install Homebrew if missing
if ! command -v brew &> /dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install packages
brew bundle --file=~/dotfiles/home/Brewfile

echo "✅ Setup complete! Restart your terminal."