#!/usr/bin/env zsh
# Unified ZSH configuration
set -e

DOTFILES="$HOME/dotfiles/home"
CONFIG="$HOME/.config"

# Create essential symlinks
ln -sf $DOTFILES/Brewfile ~/.Brewfile
ln -sf $DOTFILES/zsh/zshrc ~/.zshrc
# ln -sf $DOTFILES/zsh/.zprofile ~/.zprofile
# ln -sf $DOTFILES/zsh/.zshenv ~/.zshenv

ln -sf $DOTFILES/.config/starship.toml $CONFIG/starship.toml
ln -sf $DOTFILES/.config/nvim $CONFIG/nvim


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
