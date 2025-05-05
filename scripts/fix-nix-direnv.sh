#!/bin/bash

# Script to fix Nix direnv integration for projects
# Usage: ./fix-nix-direnv.sh [project_path]

set -e

# Default to platforms directory if no arg provided
PROJECT_DIR="${1:-$HOME/src/platform}"

if [ ! -d "$PROJECT_DIR" ]; then
	echo "Error: Project directory $PROJECT_DIR does not exist"
	exit 1
fi

echo "Fixing Nix direnv integration for $PROJECT_DIR"

# Check if .envrc already exists
if [ -f "$PROJECT_DIR/.envrc" ]; then
	echo "Backing up existing .envrc to .envrc.bak"
	cp "$PROJECT_DIR/.envrc" "$PROJECT_DIR/.envrc.bak"
fi

# Copy template to project
cp "$HOME/.config/direnv/platforms.envrc" "$PROJECT_DIR/.envrc"

# Allow the new .envrc file
cd "$PROJECT_DIR"
direnv allow

echo "Configuration applied. Try 'cd $PROJECT_DIR && nix develop' now."
echo "If you still have issues, try opening a new terminal window first."
