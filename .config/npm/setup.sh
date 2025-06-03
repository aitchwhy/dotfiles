#!/bin/bash
# NPM setup script for dotfiles

set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
NPM_CONFIG_DIR="$DOTFILES/.config/npm"
NPM_GLOBAL_DIR="$DOTFILES/.config/npm-global"

echo "Setting up npm configuration..."

# Create necessary directories
mkdir -p "$NPM_CONFIG_DIR"
mkdir -p "$NPM_GLOBAL_DIR"
mkdir -p "$HOME/.cache/npm"

# Symlink npmrc to home directory
if [ -f "$HOME/.npmrc" ] && [ ! -L "$HOME/.npmrc" ]; then
    echo "Backing up existing .npmrc to .npmrc.backup"
    mv "$HOME/.npmrc" "$HOME/.npmrc.backup"
fi

ln -sf "$NPM_CONFIG_DIR/.npmrc" "$HOME/.npmrc"
echo "✓ Linked .npmrc to home directory"

# Set npm config
npm config set prefix "$NPM_GLOBAL_DIR"
npm config set cache "$HOME/.cache/npm"
echo "✓ Set npm prefix and cache directories"

# Add npm global bin to PATH if not already there
NPM_BIN="$NPM_GLOBAL_DIR/bin"
if [[ ":$PATH:" != *":$NPM_BIN:"* ]]; then
    echo ""
    echo "Add the following to your shell configuration:"
    echo "export PATH=\"\$PATH:$NPM_BIN\""
fi

# Install global packages if requested
if [ "${1:-}" = "--install-globals" ]; then
    echo ""
    echo "Installing global packages..."
    cat "$NPM_CONFIG_DIR/global-packages.txt" | grep -v '^#' | xargs -I {} npm install -g {}
    echo "✓ Global packages installed"
fi

echo ""
echo "NPM setup complete!"
echo ""
echo "Current configuration:"
npm config list