#!/bin/bash

######################
# Example (Cursor)
# ln -sf  "/Users/hank/dotfiles/home/configs/cursor/keybindings.json "/Users/hank/Library/Application\ Support/Cursor/User/keybindings.json"
# ls -al "/Users/hank/Library/Application Support/Cursor/User"
######################

CONFIGS="$HOME/dotfiles/home/configs"

DOT_CONFIGS="$HOME/.config"
LIB_APP_SUPPORT="$HOME/Library/Application\ Support"

# ghostty
replace_with_symlink "$CONFIGS/ghostty/config" "$DOT_CONFIGS/ghostty/config"

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

# Config paths
replace_with_symlink "$CONFIGS/yazi" "$DOT_CONFIGS/yazi"
replace_with_symlink "$CONFIGS/zoxide" "$DOT_CONFIGS/zoxide"
replace_with_symlink "$CONFIGS/zellij" "$DOT_CONFIGS/zellij"
replace_with_symlink "$CONFIGS/atuin" "$DOT_CONFIGS/atuin"
replace_with_symlink "$CONFIGS/cheat" "$DOT_CONFIGS/cheat"
replace_with_symlink "$CONFIGS/zed/settings.json" "$DOT_CONFIGS/zed/settings.json"

# Replace with symlink if regular file
replace_with_symlink() {
    local source=$1
    local target=$2

    if [ -f "$target" ] && [ ! -L "$target" ]; then
        echo "Replacing $target with symlink to $source"
        rm "$target"
        ln -s "$source" "$target"
    elif [ ! -e "$target" ]; then
        echo "Creating symlink from $target to $source"
        ln -s "$source" "$target"
    fi
}

# Process each config file
for config in "${CONFIGS[@]}" "${DOT_CONFIGS[@]}" "${LIB_APP_SUPPORT[@]}"; do
    if [ -e "$config" ]; then
        source_path="$DOTFILES_ROOT/$config"
        target_path="$HOME/$config"
        
        replace_with_symlink "$source_path" "$target_path"
    fi
done

# lazygit
# gh
# yazi
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

# Replace with symlink if regular file
replace_with_symlink() {
    local source=$1
    local target=$2

    if [ -f "$target" ] && [ ! -L "$target" ]; then
        echo "Replacing $target with symlink to $source"
        rm "$target"
        ln -s "$source" "$target"
    elif [ ! -e "$target" ]; then
        echo "Creating symlink from $target to $source"
        ln -s "$source" "$target"
    fi
}

# Process each config file
for config in "${CONFIGS[@]}" "${DOT_CONFIGS[@]}" "${LIB_APP_SUPPORT[@]}"; do
    if [ -e "$config" ]; then
        source_path="$DOTFILES_ROOT/$config"
        target_path="$HOME/$config"
        
        replace_with_symlink "$source_path" "$target_path"
    fi
done
