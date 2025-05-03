# macOS Dotfiles

A collection of dotfiles and configuration for macOS (Apple Silicon) development environment.

## Features

- 🚀 One-command installation for fresh macOS systems
- 🔄 Easy updates for existing installations
- 🛠️ Comprehensive development tool setup
- ⌨️ Optimized keyboard and system preferences
- 🎨 Modern terminal and editor configurations
- 🔒 Secure and maintainable setup

## Prerequisites

- macOS (Apple Silicon)
- Git
- Curl
- Zsh

## Quick Start

### Fresh Installation

For a fresh macOS installation:

```bash
# Download and run the install script
curl -o install.zsh https://raw.githubusercontent.com/yourusername/dotfiles/main/install.zsh
chmod +x install.zsh
./install.zsh
```

This will:

1. Check system requirements
2. Set up ZSH configuration
3. Install Homebrew and packages
4. Configure CLI tools
5. Set up macOS preferences

### Existing Installation

For updating an existing installation:

```bash
# Download and run the update script
curl -o update.zsh https://raw.githubusercontent.com/yourusername/dotfiles/main/update.zsh
chmod +x update.zsh
./update.zsh
```

This will:

1. Update dotfiles repository
2. Update Homebrew packages
3. Update symlinks
4. Update macOS preferences
5. Refresh shell configuration

## Installation Options

### Install Script Options

```bash
./install.zsh [options]

Options:
  --no-brew     Skip Homebrew installation and updates
  --no-macos    Skip macOS preferences configuration
  --minimal     Install only essential configurations
  --help        Show this help message
```

## Directory Structure

```
dotfiles/
├── config/           # Configuration files
│   ├── zsh/         # ZSH configuration
│   ├── nvim/        # Neovim configuration
│   ├── git/         # Git configuration
│   └── ...          # Other tool configurations
├── install.zsh      # Fresh installation script
├── update.zsh       # Update script
├── utils.zsh        # Utility functions
└── Brewfile         # Homebrew package list
```

## Included Tools

- **Shell**: ZSH with modern plugins
- **Package Manager**: Homebrew
- **Terminal**: Ghostty
- **Editor**: Neovim
- **Version Control**: Git
- **Shell Enhancements**: Starship, Atuin, Zoxide
- **Development Tools**: Bat, Lazygit, Zellij
- **Text Expansion**: Espanso
- **Window Management**: Aerospace
- **Editors**: VSCode, Cursor
- **AI Tools**: Claude

## Optimized Configurations

The dotfiles include carefully tuned configurations for each tool:

| Tool      | Optimizations                                    |
|-----------|--------------------------------------------------|
| Aerospace | Window hints mode for fast navigation            |
| Atuin     | Workspace-aware history, hourly syncing          |
| Bat       | Terminal-matched theme, delta pager integration  |
| FZF       | Tmux-compatible popup, vim-like key navigation   |
| Git       | Safe push defaults, delta-powered diffs          |
| Glow      | Integrated with bat for uniform markdown styling |
| Htop      | IO visibility layout showing disk activity       |
| Just      | Shell integration with colorized command summary |
| Yazi      | Optimized file previews with size limits         |
| Starship  | Tokyo Night theme with right-side prompt info    |

## Customization

1. Fork this repository
2. Update the repository URL in the scripts
3. Modify configurations in the `config/` directory
4. Update the `Brewfile` with your preferred packages

## Maintenance

### Updating

Regular updates ensure you have the latest configurations and packages:

```bash
./update.zsh
```

### Backup

The installation script automatically creates backups of existing configurations in:

```
$HOME/.dotfiles_backup/YYYYMMDD_HHMMSS/
```

## Troubleshooting

### Common Issues

1. **Permission Issues**

   ```bash
   chmod +x install.zsh update.zsh
   ```

2. **Homebrew Issues**

   ```bash
   brew doctor
   brew cleanup
   ```

3. **Shell Issues**

   ```bash
   exec zsh
   ```

### Getting Help

1. Check the [Issues](https://github.com/yourusername/dotfiles/issues) page
2. Create a new issue with:
   - Your macOS version
   - Error messages
   - Steps to reproduce

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
