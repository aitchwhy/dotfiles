# Modern macOS Dotfiles (2025)

A modern, modular dotfiles management system for macOS (Apple Silicon) optimized for developer productivity. Uses symlinks and follows XDG Base Directory specification.

## Features

- 🔗 Symlink-based configuration management
- 📁 XDG Base Directory compliant
- 🧩 Modular organization
- 🚀 Modern CLI alternatives
- 🔍 Enhanced search capabilities (fzf, ripgrep, fd)
- 🔧 Comprehensive development setup
- 📦 Homebrew package management
- 🛠️ Automatic installation and updates

## Directory Structure

```
~/dotfiles/
├── README.md
├── Brewfile                    # Homebrew packages
├── config/                     # Tool configurations
│   ├── zsh/                   # Zsh configuration
│   │   ├── .zshenv           # Environment variables
│   │   ├── .zprofile         # Login shell config
│   │   ├── .zshrc            # Interactive shell config
│   │   ├── conf.d/           # Modular configurations
│   │   │   ├── options.zsh
│   │   │   ├── aliases.zsh
│   │   │   ├── functions.zsh
│   │   │   └── keybindings.zsh
│   │   └── lib/              # Shared utilities
│   ├── nvim/                 # Neovim configuration
│   ├── git/                  # Git configuration
│   └── ...                   # Other tool configs
├── scripts/                   # Setup and utility scripts
│   ├── install/
│   │   ├── brew.sh
│   │   └── macos.sh
│   ├── utils/
│   │   └── helpers.sh
│   ├── setup.sh
│   └── update.sh
└── docs/                      # Additional documentation
```

## Quick Start

1. **Clone Repository**

```bash
git clone https://github.com/aitchwhy/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

2. **Initial Setup**

```bash
# Run setup script
./scripts/setup.sh

# Install tools (requires Homebrew)
./scripts/install/brew.sh
```

3. **Update Configuration**

```bash
# Update everything
./scripts/update.sh
```

## Core Tools

### Shell Environment

- **Shell**: Zsh with modern configuration
- **Prompt**: Starship
- **History**: Atuin for better history
- **Multiplexer**: Zellij (modern tmux alternative)

### Development

- **Editor**: Neovim/VSCode/Cursor
- **Git**: Enhanced with lazygit and delta
- **Search**: ripgrep, fd, fzf
- **File Manager**: yazi
- **Terminal**: Ghostty

### Additional Tools

- **Window Management**: Hammerspoon
- **Keyboard**: Karabiner-Elements
- **Text Expansion**: Espanso
- **Task Management**: Todoist CLI

## Features

### Enhanced Shell Experience

- Modern command-line replacements:

  - `ls` → `eza` (better file listing)
  - `cat` → `bat` (syntax highlighting)
  - `find` → `fd` (faster file search)
  - `grep` → `ripgrep` (faster text search)
  - `top` → `btop` (better system monitoring)

- Improved navigation:
  - Directory jumping with zoxide
  - Fuzzy finding with fzf
  - Enhanced history with atuin

### Development Workflow

- Full development environment:

  - Python with uv for better package management
  - Node.js with volta
  - Go with proper path setup
  - Rust with cargo

- Git enhancements:
  - Better diffs with delta
  - Interactive UI with lazygit
  - Fuzzy branch switching
  - Custom aliases and functions

### File Organization

- XDG Base Directory compliance:
  - Configurations in ~/.config
  - Cache in ~/.cache
  - Data in ~/.local/share
  - State in ~/.local/state

## Customization

### Adding New Tools

1. Create configuration in `~/dotfiles/config/<tool>/`
2. Add symlink mapping to `scripts/setup.sh`
3. Add packages to `Brewfile` if needed
4. Run `./scripts/setup.sh` to create symlinks

### Modifying Existing Configs

1. Edit files in `~/dotfiles/config/`
2. Changes are immediate due to symlinks
3. Commit changes to track in git

## Installation Details

### Prerequisites

- macOS 15.3.1+ (Sequoia)
- Apple Silicon Mac
- Command Line Tools (`xcode-select --install`)
- Git

### Installation Steps

1. **Command Line Tools**

```bash
xcode-select --install
```

2. **Clone Repository**

```bash
git clone https://github.com/aitchwhy/dotfiles.git ~/dotfiles
```

3. **Run Setup**

```bash
cd ~/dotfiles
./scripts/setup.sh
```

4. **Install Tools**

```bash
./scripts/install/brew.sh
```

### Post-Installation

1. **Shell Setup**

```bash
# Change default shell to Zsh
chsh -s $(which zsh)
```

2. **Tool Configuration**

```bash
# Initialize tools
atuin init zsh
starship init zsh
```

## Maintenance

### Updates

```bash
# Update everything
./scripts/update.sh

# Update specific components
brew update && brew upgrade  # Update Homebrew packages
nvim +PackerSync            # Update Neovim plugins
```

### Backups

- All configurations backed up before modification
- Backups stored in ~/.dotfiles_backup
- Dated backup folders for easy restoration

## Troubleshooting

### Common Issues

1. **Broken Symlinks**

```bash
# Fix symlinks
./scripts/setup.sh --force
```

2. **Tool Not Found**

```bash
# Verify Homebrew installation
brew doctor

# Reinstall tools
brew bundle --global
```

3. **Configuration Not Loading**

```bash
# Reload shell
exec zsh

# Check paths
echo $ZDOTDIR
echo $XDG_CONFIG_HOME
```

## Additional Documentation

- [Tool List](docs/TOOLS.md)
- [Installation Guide](docs/INSTALL.md)
- [Customization Guide](docs/CUSTOMIZE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## License

MIT

## Acknowledgments

- [Modern Unix Tools](https://github.com/ibraheemdev/modern-unix)
- [Awesome Dotfiles](https://github.com/webpro/awesome-dotfiles)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
