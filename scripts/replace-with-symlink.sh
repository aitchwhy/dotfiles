#!/bin/bash

######################
# Example (Cursor)
# ln -sf  "/Users/hank/dotfiles/home/configs/cursor/keybindings.json "/Users/hank/Library/Application\ Support/Cursor/User/keybindings.json"
# ls -al "/Users/hank/Library/Application Support/Cursor/User"
######################

# Exit if any command fails
set -e

# Base directories
DOTFILES_ROOT="$HOME/dotfiles"
CONFIGS="$DOTFILES_ROOT/home/configs"
DOT_CONFIGS="$HOME/.config"
LIB_APP_SUPPORT="$HOME/Library/Application Support"

# Replace with symlink if regular file
replace_with_symlink() {
    local source=$1
    local target=$2

    # Create target directory if it doesn't exist
    mkdir -p "$(dirname "$target")"

    if [ -f "$target" ] && [ ! -L "$target" ]; then
        echo "Replacing $target with symlink to $source"
        rm "$target"
        ln -s "$source" "$target"
    elif [ ! -e "$target" ]; then
        echo "Creating symlink from $target to $source"
        ln -s "$source" "$target"
    fi
}

# Config paths
replace_with_symlink "$CONFIGS/ghostty/config" "$DOT_CONFIGS/ghostty/config"
replace_with_symlink "$CONFIGS/karabiner/karabiner.json" "$DOT_CONFIGS/karabiner/karabiner.json"
replace_with_symlink "$CONFIGS/cursor/keybindings.json" "$LIB_APP_SUPPORT/Cursor/User/keybindings.json"
replace_with_symlink "$CONFIGS/starship/starship.toml" "$DOT_CONFIGS/starship/starship.toml"
replace_with_symlink "$CONFIGS/nvim/init.lua" "$DOT_CONFIGS/nvim/init.lua"
replace_with_symlink "$CONFIGS/yazi" "$DOT_CONFIGS/yazi"
replace_with_symlink "$CONFIGS/zoxide" "$DOT_CONFIGS/zoxide"
replace_with_symlink "$CONFIGS/zellij" "$DOT_CONFIGS/zellij"
replace_with_symlink "$CONFIGS/atuin" "$DOT_CONFIGS/atuin"
replace_with_symlink "$CONFIGS/cheat" "$DOT_CONFIGS/cheat"
replace_with_symlink "$CONFIGS/zed/settings.json" "$DOT_CONFIGS/zed/settings.json"
replace_with_symlink "$CONFIGS/lazygit" "$DOT_CONFIGS/lazygit"
replace_with_symlink "$CONFIGS/gh" "$DOT_CONFIGS/gh"

# Optional: Process additional config files from arrays if needed
# for config in "${ADDITIONAL_CONFIGS[@]}"; do
#     if [ -e "$CONFIGS/$config" ]; then
#         source_path="$CONFIGS/$config"
#         target_path="$DOT_CONFIGS/$config"
#         replace_with_symlink "$source_path" "$target_path"
#     fi
# done

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
