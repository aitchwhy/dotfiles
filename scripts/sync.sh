#!/bin/zsh
# Dotfiles synchronization script

# Backup and sync config files
rsync -avz ~/.zshrc ~/dotfiles/zsh/
rsync -avz ~/.config/nvim/ ~/dotfiles/config/nvim/
rsync -avz ~/.config/starship.toml ~/dotfiles/config/

# Update Brewfile and Masfile
brew bundle dump --force --file=~/dotfiles/Brewfile
mas list | awk '{print $1}' > ~/dotfiles/Masfile

# Commit changes
cd ~/dotfiles
git add .
git commit -m "Sync: $(date +'%Y-%m-%d %H:%M:%S')"
git push origin main