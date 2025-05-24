# Yazi Configuration

A modern, GPU-accelerated terminal file manager with Tokyo Night theme, Neovim integration, and optimized performance for Apple Silicon.

## Overview

This configuration enhances Yazi with:

- Tokyo Night theme-inspired colors and UI
- Enhanced macOS integration (tags, QuickLook, Finder)
- Optimized performance for Apple Silicon
- Neovim and VS Code integration
- Rich file previews with syntax highlighting
- Smart navigation and operations

## Features

- 🎨 **Tokyo Night Theme**: Consistent styling with custom borders and colors
- 🔍 **Enhanced Previews**: Rich text, code, archive, and media previews
- 🏷️ **macOS Tags**: Native macOS tag integration with color-coded indicators
- ⚡ **Optimized Performance**: Configured for Apple Silicon with higher worker counts
- 📁 **Smart Folder Rules**: Custom layouts and sorting for different directories
- 🧭 **Quick Navigation**: Bunny hops for jumping to common locations
- 🔗 **Symlink Handling**: Better display and navigation of symbolic links
- 🔄 **Git Integration**: Show git branch and status in repositories
- 📝 **Editor Integration**: Seamless integration with Neovim and VS Code

## Core Configuration

The configuration consists of two main files:

1. **yazi.toml**: Base configuration with settings for:
   - File manager behavior
   - Preview settings
   - Task processing
   - File openers and rules
   - Plugin setup

2. **init.lua**: Plugin setup and customizations including:
   - Custom UI with rounded borders
   - macOS tag integration
   - Enhanced mime-type detection
   - Smart folder rules
   - Navigation enhancements

## Key Bindings

| Shortcut | Action |
|----------|--------|
| `h/j/k/l` | Navigate files/directories |
| `Enter` | Open file/directory |
| `q` | Back/Quit |
| `Space` | Select/Deselect file |
| `v` | Toggle visual mode |
| `c` | Copy selected files |
| `x` | Cut selected files |
| `p` | Paste files |
| `a` | Create new file |
| `A` | Create new directory |
| `d` | Move to trash |
| `D` | Permanently delete |
| `y` | Copy file path |
| `r` | Bulk rename |
| `:` | Enter command mode |
| `z` | Change sort order |
| `s` | Search/filter in current directory |
| `Tab` | Switch between panes |
| `Ctrl+h/l` | Go back/forward in history |

### Plugin-specific Bindings

| Shortcut | Action |
|----------|--------|
| `g` + `key` | Bunny hop to specified location |
| `f` + `char` | Jump to character in current view |
| `t` + `key` | Toggle macOS tag color |
| `?` | Show all keybindings |

## Performance Optimizations

The configuration is optimized for Apple Silicon with:

```toml
[tasks]
  # Optimized for Apple Silicon
  micro_workers = 12
  macro_workers = 16
  bizarre_retry = 5
  delay_chain_threshold = 10
```

## File Openers

The configuration includes customized openers for different file types:

- Text files: Opens with Neovim
- Images: Opens with Preview app
- Code files: Opens with Neovim or VS Code
- Archives: Extracts with appropriate tools
- URLs: Opens with Safari
- All other files: Opens with default macOS app

## Previews

Enhanced file previews:

- Code with syntax highlighting via bat
- Markdown with glow
- JSON and CSV with rich-preview
- Archives with ouch and tar viewers
- Images with native preview
- Fallback to hexyl for binary files

## Folder-specific Rules

Custom rules for specific folders:

- **~/dotfiles**: Custom layout, always show hidden files
- **~/Downloads**: Sort by modification time (newest first)
- **~/.config**: Always show hidden files

## Installation

This configuration is installed automatically by the setup.sh script.

For manual installation:

1. Install Yazi: `brew install yazi`
2. Create the config directory: `mkdir -p ~/.config/yazi`
3. Symlink the configuration:
   ```bash
   ln -sf ~/dotfiles/config/yazi/yazi.toml ~/.config/yazi/yazi.toml
   ln -sf ~/dotfiles/config/yazi/init.lua ~/.config/yazi/init.lua
   ln -sf ~/dotfiles/config/yazi/keymap.toml ~/.config/yazi/keymap.toml
   ln -sf ~/dotfiles/config/yazi/theme.toml ~/.config/yazi/theme.toml
   ```
4. Symlink plugin and theme directories:
   ```bash
   ln -sf ~/dotfiles/config/yazi/plugins ~/.config/yazi/plugins
   ln -sf ~/dotfiles/config/yazi/flavors ~/.config/yazi/flavors
   ```

## Dependencies

- `bat` - Syntax highlighting for file previews
- `eza` - Enhanced directory listings
- `glow` - Markdown previewing
- `hexyl` - Hex viewer for binary files
- `unar` - Archive extraction tool
- `ripgrep` - Fast text search

## Resources

- [Yazi Documentation](https://yazi-rs.github.io/)
- [Yazi GitHub](https://github.com/sxyazi/yazi)
- [Yazi Plugins Repository](https://github.com/yazi-rs/plugins)