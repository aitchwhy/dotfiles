# System Environment Snapshot

This document provides a comprehensive snapshot of the system environment at the time of the last update.

## System Information

- **OS**: macOS (Darwin 24.4.0)
- **Platform**: Apple Silicon (arm64)
- **User**: hank
- **Directory**: /Users/hank/dotfiles
- **Date**: 2025-05-03

## Repository Information

- **Branch**: main
- **Last Commit**: f109687 "Add comprehensive READMEs and setup script"
- **Commit Date**: 2025-05-03

## Core Tools

| Tool | Version | Package Manager |
|------|---------|-----------------|
| Zsh | 5.2.37 | Homebrew |
| Neovim | 0.11.1 | Homebrew |
| Git | 2.49.0 | Homebrew |
| Homebrew | latest | System |
| Just | 1.40.0 | Homebrew |
| Starship | 1.23.0 | Homebrew |
| Yazi | 25.4.8 | Homebrew |
| Aerospace | 0.18.4-Beta | Homebrew |
| Ghostty | 1.1.3 | Homebrew |

## Terminal Environment

- **Shell**: Zsh
- **Terminal**: Ghostty
- **Prompt**: Starship with Tokyo Night theme
- **Multiplexer**: Zellij (0.42.2)
- **File Manager**: Yazi (25.4.8)
- **Window Manager**: Aerospace (0.18.4-Beta)

## Tool Integration

- **History Management**: Atuin (18.5.0)
- **Directory Navigation**: Zoxide (0.9.7)
- **Fuzzy Finder**: FZF (0.61.3)
- **Task Runner**: Just (1.40.0)
- **File Listing**: Eza (0.21.3)
- **Text Viewing**: Bat (0.25.0)
- **File Searching**: Ripgrep (14.1.1), Fd (10.2.0)

## Development Environment

- **Node.js**: 23.11.0 (via Volta 2.0.2)
- **Python**: 3.12.10, 3.13.3
- **Go**: 1.24.2
- **Rust**: via Rustup 1.28.1
- **Text Editors**: Neovim (0.11.1), VS Code (1.98.2), Cursor (0.48.8)

## Primary Configuration Locations

- **Dotfiles**: ~/dotfiles
- **Config**: ~/.config
- **Cache**: ~/.cache
- **Local Data**: ~/.local/share
- **State**: ~/.local/state

## Environment Variables

Key environment variables that affect the configuration:

```
DOTFILES=/Users/hank/dotfiles
XDG_CONFIG_HOME=/Users/hank/.config
XDG_CACHE_HOME=/Users/hank/.cache
XDG_DATA_HOME=/Users/hank/.local/share
XDG_STATE_HOME=/Users/hank/.local/state
ZDOTDIR=/Users/hank/.config/zsh
EDITOR=nvim
VISUAL=nvim
STARSHIP_CONFIG=/Users/hank/dotfiles/config/starship/starship.toml
ATUIN_CONFIG_DIR=/Users/hank/dotfiles/config/atuin
YAZI_CONFIG_DIR=/Users/hank/dotfiles/config/yazi
ZELLIJ_CONFIG_DIR=/Users/hank/dotfiles/config/zellij
```

## Dotfiles Catalog

Major configuration files and directories:

```
~/dotfiles/
├── config/              # Configuration files
│   ├── aerospace/       # Window manager
│   ├── ai/              # AI tools (Claude, Cline)
│   ├── atuin/           # Shell history
│   ├── bat/             # Cat replacement
│   ├── ghostty/         # Terminal emulator
│   ├── git/             # Git configuration
│   ├── hammerspoon/     # macOS automation
│   ├── nvim/            # Neovim configuration
│   ├── starship/        # Prompt configuration
│   ├── vscode/          # VS Code settings
│   ├── yazi/            # File manager
│   ├── zellij/          # Terminal multiplexer
│   └── zsh/             # Shell configuration
├── scripts/             # Utility scripts
│   └── setup.sh         # Setup script
├── justfile             # Task runner configuration
├── README.md            # Main documentation
└── CLAUDE.md            # Claude AI instructions
```

## Homebrew Status

- **Number of Formulae**: 283
- **Number of Casks**: 74
- **Core Packages**: See Brewfile.core
- **Full Package List**: See Brewfile.full

## Primary Functions

Key functions available in the shell environment:

- `has_command`: Check if a command exists
- `path_add`: Add a directory to PATH
- `f`: FZF-enhanced file finder
- `fgit`: FZF-enhanced git log browser
- `j`: Run Just commands
- `jf`: Fuzzy-find Just commands
- `ja <tool>`: Fuzzy-find tool-specific Just commands

## Update Process

Last update process:

1. Updated repository with `git pull`
2. Ran setup script with `./scripts/setup.sh`
3. Updated Homebrew packages with `brew update && brew upgrade`
4. Created symlinks for configuration files
5. Updated documentation with current versions