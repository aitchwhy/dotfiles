#!/bin/bash

# Configure VS Code settings and extensions
# This script should be run after VS Code is installed

# Ensure script stops on error
set -e

# Install VS Code extensions
install_vscode_extensions() {
	echo "Installing VS Code extensions..."
	if ! command -v code >/dev/null 2>&1; then
		echo "⚠️ VS Code command line tool not found. Please run 'Install Code Command in PATH'"
		return 1
	fi
	
	# Install extensions from file
	cat vscode-extensions.txt | grep -v '^#' | xargs -L 1 code --install-extension
	echo "✅ Extensions installed."
}

# Configure VS Code settings
configure_vscode_settings() {
	echo "Configuring VS Code settings..."
	mkdir -p "$HOME/Library/Application Support/Code/User"
	cp vscode-settings.json "$HOME/Library/Application Support/Code/User/settings.json"
	echo "✅ Settings configured."
}

# Main
echo "Setting up VS Code..."
install_vscode_extensions
configure_vscode_settings
echo "✅ VS Code setup complete!"
