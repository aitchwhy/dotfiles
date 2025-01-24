#!/bin/bash

# Exit if any command fails
set -e

# Check if a file path is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <target-file-path>"
  exit 1
fi

TARGET_FILE="$1"
DOTFILES_DIR="$HOME/dotfiles/darwin"
BASENAME=$(basename "$TARGET_FILE")
NEW_NAME="${BASENAME}.core"

# Ensure the target directory exists
mkdir -p "$DOTFILES_DIR"

# Move the file to the dotfiles directory and rename it
mv "$TARGET_FILE" "$DOTFILES_DIR/$NEW_NAME"

# Create a symlink in the original location pointing to the new location
ln -s "$DOTFILES_DIR/$NEW_NAME" "$TARGET_FILE"

echo "File moved to $DOTFILES_DIR/$NEW_NAME and symlink created at $TARGET_FILE"
