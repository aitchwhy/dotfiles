#!/usr/bin/env bash

mkdir -p "$ZDOTDIR"

slink "$DOTFILES/zsh/zshenv" "$HOME/.zshenv"
slink "$DOTFILES/zsh/.zshrc" "$ZDOTDIR/.zshrc"
# slink $DOTFILES/.zshrc $HOME/.zshrc

slink "$DOTFILES/zsh/dircolors" "$ZDOTDIR/dircolors"

slink $DOTFILES/.Brewfile $HOME/.Brewfile

# slink $DOTFILES_EXPORTS $OMZ_CUSTOM/exports.zsh
# slink $DOTFILES_ALIASES $OMZ_CUSTOM/aliases.zsh
# slink $DOTFILES_FUNCTIONS $OMZ_CUSTOM/functions.zsh

# slink $DOTFILES/nvm/default-packages $NVM_DIR/default-packages
# slink $DOTFILES/config/git/.gitignore $HOME/.gitignore




