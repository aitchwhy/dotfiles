# dotfiles

## Directory Structure

```
~/dotfiles/
├── README.md
├── install.sh
├── update.sh
├── utils.sh
├── Brewfile                      # Homebrew packages
├── config/                       # Tool configurations
│   ├── zsh/                      # Zsh configuration
│   │   ├── .zshenv               # Environment variables
│   │   ├── .zprofile             # Login shell config
│   │   ├── .zshrc                # Interactive shell config
│   │   └── conf.d/               # Modular configurations
│   │       ├── fzf.zsh
│   │       ├── aliases.zsh
│   │       └── functions.zsh
│   ├── nvim/                     # Neovim configuration
│   ├── git                      # Git configuration
│   │   ├── config
│   │   └── ignore
│   └── ...                   # Other tool configs

├── scripts/                   # Setup and utility scripts
│
└── docs/
```

## Installation

1. **Clone Repository**

```bash
git clone https://github.com/aitchwhy/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

2. **Initial Setup**

```bash

# Run install script
./install.sh

```

3. **Update Configuration**

```bash
# Update everything
./update.sh
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

## References

- TODO: <https://randomgeekery.org/config/shell/zsh/>
- <https://claude.ai/chat/3aa18a69-65af-499a-b849-29e633ad15dc>
- <https://chatgpt.com/c/67a3ecfb-9f94-8012-9c66-fd98cd4bb5b2>
- <https://github.com/getantidote/zdotdir/blob/main/.zshenv>
