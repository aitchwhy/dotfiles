#!/bin/bash

# Setup script for new macOS Apple Silicon machine
set -e

echo "Starting setup for new macOS machine..."

# Install Xcode Command Line Tools
echo "Installing Xcode Command Line Tools..."
xcode-select --install 2>/dev/null || echo "Xcode CLI tools already installed or installing"
until xcode-select -p &>/dev/null; do
	sleep 10
	echo "Still waiting for Xcode CLI tools..."
done
echo "✅ Xcode Command Line Tools installed."

# Install Homebrew
echo "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>$HOME/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install packages from Brewfile
echo "Installing packages from Brewfile..."
brew bundle

# Configure NVM
echo "Configuring NVM..."
mkdir -p $HOME/.nvm
if ! grep -q "NVM Configuration" $HOME/.zshrc; then
	cat >>$HOME/.zshrc <<'EOF'

# NVM Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
EOF
fi

# Configure direnv
echo "Configuring direnv..."
if ! grep -q "direnv Configuration" $HOME/.zshrc; then
	cat >>$HOME/.zshrc <<'EOF'

# direnv Configuration
eval "$(direnv hook zsh)"
EOF
fi

# Configure Python DLLs
echo "Configuring Python environment..."
if ! grep -q "Python DLL fallback paths" $HOME/.zshrc; then
	cat >>$HOME/.zshrc <<'EOF'

# Python DLL fallback paths
export DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib:$DYLD_FALLBACK_LIBRARY_PATH
EOF
fi

# Install VS Code extensions
if command -v code >/dev/null 2>&1; then
	echo "Installing VS Code extensions..."
	if [ -f "vscode-extensions.txt" ]; then
		cat vscode-extensions.txt | grep -v '^#' | xargs -L 1 code --install-extension
	fi
fi

# Configure VS Code settings
if [ -d "$HOME/Library/Application Support/Code/User" ]; then
	echo "Configuring VS Code settings..."
	if [ -f "vscode-settings.json" ]; then
		cp vscode-settings.json "$HOME/Library/Application Support/Code/User/settings.json"
	fi
fi

# Post-installation steps
echo ""
echo "✅ Installation complete!"
echo ""
echo "🔍 Manual steps required:"
echo "1. Run: source ~/.zshrc"
echo "2. Setup Node.js: nvm install v22.14.0 && nvm use 22.14.0 && nvm alias default 22.14.0" 
echo "3. Configure Orbstack: Enable HTTPS for container domains"
echo "4. Setup Tailscale: Sign into your network"
echo "5. 1Password: Enable CLI integration in Settings > Developer"
