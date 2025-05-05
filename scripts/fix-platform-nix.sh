#!/bin/bash
# Script to fix Nix integration for the platform directory

set -e

# Default platform directory
PLATFORM_DIR="${1:-$HOME/src/platform}"

if [ ! -d "$PLATFORM_DIR" ]; then
  echo "Error: Platform directory $PLATFORM_DIR does not exist"
  exit 1
fi

echo "Fixing Nix integration for $PLATFORM_DIR"

# Ensure config directories exist
mkdir -p "$HOME/.config/nix"

# Copy shell compatibility file
cp "$HOME/dotfiles/config/nix/shell-compat.sh" "$HOME/.config/nix/"
chmod +x "$HOME/.config/nix/shell-compat.sh"

# Backup existing .envrc if it exists
if [ -f "$PLATFORM_DIR/.envrc" ]; then
  echo "Backing up existing .envrc to .envrc.bak"
  cp "$PLATFORM_DIR/.envrc" "$PLATFORM_DIR/.envrc.bak"
fi

# Copy our new .envrc file
cp "$HOME/dotfiles/config/nix/platform.envrc" "$PLATFORM_DIR/.envrc"

# Allow the new .envrc
cd "$PLATFORM_DIR"
direnv allow

echo "=========================================================="
echo "To use the new configuration:"
echo "1. Open a new terminal window"
echo "2. Navigate to your platform directory: cd $PLATFORM_DIR"
echo "3. Try running: nix develop"
echo "4. If issues persist, try: nix develop --command zsh"
echo "=========================================================="