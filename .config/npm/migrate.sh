#!/bin/bash
# Migration script from old npm setup to new setup

set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
NPM_CONFIG_DIR="$DOTFILES/.config/npm"
OLD_CONFIG="$NPM_CONFIG_DIR/.npm-global"
NEW_CONFIG="$NPM_CONFIG_DIR/.npmrc"

echo "Migrating npm configuration..."

# Check if old config exists
if [ -f "$OLD_CONFIG" ]; then
    echo "Found old config file: $OLD_CONFIG"
    
    # Check if new config already exists
    if [ -f "$NEW_CONFIG" ]; then
        echo "New config already exists. Old config will be kept as .npm-global.old"
        mv "$OLD_CONFIG" "$OLD_CONFIG.old"
    else
        echo "ERROR: New config should have been created by setup. Please run setup.sh first."
        exit 1
    fi
else
    echo "No old config file found. Migration may have already been completed."
fi

# Check for old environment variable in shell config
if grep -q "NPM_CONFIG_USERCONFIG" "$HOME/.zshrc" 2>/dev/null || \
   grep -q "NPM_CONFIG_USERCONFIG" "$DOTFILES/.config/zsh/.zshrc" 2>/dev/null; then
    echo ""
    echo "Found NPM_CONFIG_USERCONFIG in shell configuration."
    echo "This has been commented out in .config/zsh/.zshrc"
    echo "Please restart your shell or run: source ~/.zshrc"
fi

# List current global packages for reference
echo ""
echo "Current global packages:"
npm list -g --depth=0

echo ""
echo "Migration complete!"
echo ""
echo "Next steps:"
echo "1. Restart your shell or run: source ~/.zshrc"
echo "2. Verify npm config with: npm config list"
echo "3. If everything works, you can delete $OLD_CONFIG.old"