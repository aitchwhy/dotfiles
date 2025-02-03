#!/bin/zsh
# Comprehensive installation script for macOS Sequoia (Apple Silicon)

set -e  # Exit immediately on error

# Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install
fi

# Homebrew setup
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Create symlinks with conflict resolution
echo "🔗 Creating symlinks..."
link_files=(
  "zsh/.zshrc ~/.zshrc"
  "config/starship.toml ~/.config/starship.toml"
  "config/nvim ~/.config/nvim"
  "config/yazi ~/.config/yazi"
  "config/karabiner ~/.config/karabiner"
  "config/zellij ~/.config/zellij"
  "config/brew/Brewfile ~/Brewfile"
  "config/brew/Masfile ~/Masfile"
)

for pair in "${link_files[@]}"; do
  src=~/dotfiles/${pair%% *}
  dest=${pair#* }
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "Backing up existing $dest"
    mv "$dest" "${dest}.bak"
  fi
  mkdir -p "$(dirname "$dest")"
  ln -sfv "$src" "$dest"
done

# Install packages
echo "🍺 Installing Homebrew packages..."
brew bundle --file=~/dotfiles/config/brew/Brewfile

echo "📱 Installing Mac App Store apps..."
mas install $(cat ~/dotfiles/config/brew/Masfile | grep -v '^#' | cut -d' ' -f4)

# Setup project directories
echo "📂 Creating project structure..."
~/dotfiles/scripts/setup_project_dirs.sh

echo "🎉 Setup complete! Restart your terminal."