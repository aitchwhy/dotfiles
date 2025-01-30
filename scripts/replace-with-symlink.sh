#!/bin/bash

######################
# Example (Cursor)
# ln -sf  /Users/hank/dotfiles/home/configs/cursor/keybindings.json /Users/hank/Library/Application\ Support/Cursor/User/keybindings.json
######################

SRC_CONFIG_DIR="$HOME/dotfiles/home/configs"

DST_CONFIG_DIR="$HOME/.config"
DST_LIB_DIR="$HOME/Library/Application\ Support"

# ghostty
ln -sf $SRC_CONFIG_DIR/ghostty/config $DST_CONFIG_DIR/ghostty/config

# karabiner
ln -sf $SRC_CONFIG_DIR/karabiner/karabiner.json $DST_CONFIG_DIR/.config/karabiner/karabiner.json

# Cursor (App)
# /Users/hank/Library/Application\ Support/Cursor/User/keybindings.json
ln -sf $SRC_CONFIG_DIR/Cursor/User/keybindings.json  $SRC_CONFIG_DIR/Cursor/User/keybindings.json ~/.config/cursor/keybindings.json
ln -sf $CONFIG_DIR/cursor/keybindings.json ~/.config/cursor/keybindings.json

# starship
ln -sf $CONFIG_DIR/starship/starship.toml ~/.config/starship/starship.toml

# nvim
ln -sf $CONFIG_DIR/nvim/init.lua ~/.config/nvim/init.lua

# lazygit
# gh
# yazi
# zoxide
# zellij
# atuin
# cheat
# zed




########################
# TODO: generic CLI version
########################

# # Exit if any command fails
# set -e

# # Check if a file path is provided
# if [ -z "$1" ]; then
#   echo "Usage: $0 <target-file-path>"
#   exit 1
# fi

# TARGET_FILE="$1"
# DOTFILES_DIR="$HOME/dotfiles/darwin"
# BASENAME=$(basename "$TARGET_FILE")
# NEW_NAME="${BASENAME}.core"

# # Ensure the target directory exists
# mkdir -p "$DOTFILES_DIR"

# # Move the file to the dotfiles directory and rename it
# mv "$TARGET_FILE" "$DOTFILES_DIR/$NEW_NAME"

# # Create a symlink in the original location pointing to the new location
# ln -s "$DOTFILES_DIR/home/$NEW_NAME" "$TARGET_FILE"

# echo "File moved to $DOTFILES_DIR/$NEW_NAME and symlink created at $TARGET_FILE"
