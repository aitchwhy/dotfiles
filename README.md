# Dotfiles for macOS

A comprehensive dotfiles management system for macOS on Apple Silicon. This repository contains scripts and configuration files to set up a complete macOS environment with modern tools, sensible defaults, and productivity enhancements.

## Quick Start

```zsh
# Clone the repository
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run the installer
./install.zsh

# Start a new shell session
exec zsh
```

## Features

- **ZSH Configuration**: Modern shell setup with plugins and useful functions
- **Homebrew Integration**: Install and manage CLI tools and applications
- **Development Environment**: Configuration for Python, Node.js, Rust, and more
- **GUI Applications**: Configuration for VS Code, Cursor, Hammerspoon, etc.
- **macOS Preferences**: Optimized system settings for productivity
- **Robust Backup System**: Automatic backup of existing configurations
- **Smart Symlink Management**: Clean handling of existing files and links

## System Requirements

- macOS on Apple Silicon (M1/M2/M3)
- Git
- Internet connection for downloading packages

## Available Scripts

- `install.zsh`: Main installation script
- `update.zsh`: Update dotfiles and installed packages
- `utils.sh`: Shared utility functions

### Installation Options

```
./install.zsh [options]

Options:
  --no-brew     Skip Homebrew installation and updates
  --no-macos    Skip macOS preferences configuration
  --minimal     Install only essential configurations
  --help        Show help message
```

### Update Options

```
./update.zsh [options]

Options:
  --no-brew     Skip Homebrew updates
  --no-apps     Skip App Store and VSCode updates
  --no-repo     Skip dotfiles repository update
  --fix-links   Attempt to fix broken symlinks
  --quick       Quick update (only dotfiles and relink)
  --help        Show help message
```

## Directory Structure

```
~/dotfiles/
├── Brewfile               # Homebrew packages and applications
├── install.zsh            # Main installation script
├── update.zsh             # Update script
├── utils.sh               # Shared utility functions
├── config/                # Configuration files
│   ├── zsh/               # ZSH configuration
│   │   ├── .zshrc         # Main ZSH configuration
│   │   ├── .zshenv        # ZSH environment variables
│   │   └── .zprofile      # Login shell configuration
│   ├── starship.toml      # Starship prompt configuration
│   ├── nvim/              # Neovim configuration
│   ├── vscode/            # VS Code settings
│   ├── hammerspoon/       # Hammerspoon configuration
│   └── ...                # Other app configurations
└── README.md              # This file
```

## What Gets Installed

- **Shell Environment**: ZSH with modern plugins and prompt
- **Command Line Tools**: Git, Homebrew, FZF, Ripgrep, Bat, etc.
- **Programming Languages**: Python, Node.js, Rust toolchains
- **Development Tools**: VS Code, Neovim, Git clients
- **Productivity Apps**: Hammerspoon, Karabiner-Elements

## How It Works

1. **Repository Verification**: Checks that the repository structure is valid
2. **Backup**: Backs up existing configuration files to `~/.dotfiles_backup/DATE_TIME/`
3. **ZSH Setup**: Creates `.zshenv` that points to the dotfiles ZSH configuration
4. **Homebrew**: Installs and updates Homebrew packages from the Brewfile
5. **Configuration**: Links configuration files to their proper locations
6. **Development**: Sets up development environments if requested
7. **macOS Preferences**: Configures system settings for productivity

## Customization

1. **Fork the Repository**: Create your own fork of this repository
2. **Edit the Brewfile**: Add or remove packages you need
3. **Modify Configurations**: Edit the files in the `config/` directory
4. **Run the Installer**: Execute `./install.zsh` to apply your changes

## Maintaining Your Dotfiles

- **Regular Updates**: Run `./update.zsh` to keep everything in sync
- **New Machine Setup**: Clone your repository and run `./install.zsh`
- **Backing Up Changes**: Commit and push your changes to your GitHub repository

## Troubleshooting

- **Broken Symlinks**: Run `./update.zsh --fix-links` to repair
- **Permission Issues**: Make sure scripts are executable with `chmod +x *.zsh`
- **Path Problems**: Check `~/.zshenv` and ensure it points to the correct location

## License

This project is open source and available under the MIT License.
