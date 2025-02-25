# macOS Dotfiles Installation Guide

This guide helps you set up a complete macOS environment using the provided dotfiles scripts. The setup works for both fresh installations and existing macOS systems on Apple Silicon machines.

## Overview

The dotfiles system includes:

- ZSH configuration with modern plugins
- Homebrew package management
- CLI tool configurations (starship, atuin, bat, etc.)
- GUI application configurations (VSCode, Cursor, Hammerspoon, etc.)
- macOS system preferences
- Development environment setup

## Prerequisites

- A macOS system running on Apple Silicon (M1/M2/M3)
- Administrator access
- Internet connection

## Quick Start

For new installations or if you don't already have a dotfiles structure:

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
   ```

2. If starting from scratch, first create the dotfiles structure:
   ```bash
   cd ~/dotfiles
   chmod +x ./create-dotfiles.sh
   ./create-dotfiles.sh
   ```

3. Run the main setup script:
   ```bash
   chmod +x ./setup-script.sh
   ./setup-script.sh
   ```

4. Restart your shell:
   ```bash
   exec zsh
   ```

## What Gets Installed

### Directory Structure

The setup creates and configures these directories:

- `$HOME/.config` - XDG config directory
- `$HOME/.cache` - XDG cache directory  
- `$HOME/.local/share` - XDG data directory
- `$HOME/dotfiles` - Your dotfiles repository

### Configuration Files

The setup links these configuration files:

- `.zshenv`, `.zshrc`, `.zprofile` - ZSH configuration
- `starship.toml` - Shell prompt configuration
- `atuin/config.toml` - Shell history configuration
- `bat/config` - Syntax highlighting configuration
- `zellij/config.yml` - Terminal multiplexer configuration
- VSCode, Cursor, Karabiner, and Hammerspoon configurations

### Applications

The Homebrew packages from your Brewfile include:

- CLI tools: git, fzf, ripgrep, starship, nvim, and more
- GUI applications: VSCode, Hammerspoon, Claude, and more
- Useful utilities for development and productivity

### Development Setup

- Python environment with pyenv (if installed)
- Node.js environment with fnm (if installed)
- Git configuration
- Development directories

## Customization

You can customize the setup by:

1. Modifying the `Brewfile` to add or remove packages
2. Editing the configuration files in `~/dotfiles/config/`
3. Adjusting macOS preferences in the `setup_macos_preferences` function

## Troubleshooting

If you encounter issues:

- Check the output for error messages
- Ensure you have proper permissions
- For Homebrew errors, try running `brew doctor`
- For symlink issues, check that source files exist

## Maintenance

To keep your system updated:

- Run the setup script periodically to sync new configurations
- Update Homebrew packages with `brew update && brew upgrade`
- Commit changes to your dotfiles repository

## Advanced Usage

### Adding New Configuration Files

1. Add the file to your dotfiles repository
2. Add a symlink in the appropriate setup function
3. Run the setup script again

### Removing Configuration

To remove configuration:
1. Delete the symlink
2. Optionally restore from backup (located next to the symlink with a `.backup-DATE` suffix)

## License

This project is open source and available under the MIT License.
