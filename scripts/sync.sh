#!/bin/zsh
# Sync local changes back to repository

set -e

echo "🔄 Syncing configuration changes..."
rsync -avz --relative \
  ~/.zshrc \
  ~/.config/nvim/ \
  ~/.config/yazi/ \
  ~/.config/starship.toml \
  ~/Brewfile \
  ~/Masfile \
  ~/dotfiles/

echo "📦 Updating package lists..."
brew bundle dump --force --file=~/dotfiles/config/brew/Brewfile
mas list | awk '{print $1}' > ~/dotfiles/config/brew/Masfile

echo "💾 Committing changes..."
cd ~/dotfiles
git add .
git commit -m "Sync: $(date +'%Y-%m-%d %H:%M:%S')"
git push origin main

echo "✅ Sync complete!"