# Aerospace Configuration

Advanced window management for macOS using Aerospace, with Tokyo Night theme-inspired window gaps and highly efficient keyboard shortcuts.

## Overview

This configuration provides a tiling window manager experience on macOS with:

- Vim-style window navigation (alt + h/j/k/l)
- Multiple workspace support (alt + 1-5)
- Efficient window layouts (tiles, accordion, floating)
- Tokyo Night theme-inspired window gaps
- Modal key binding system

## Key Features

- **Window Navigation**: Vim-style keybindings for intuitive navigation
- **Window Layouts**: Support for tiling, accordion, and floating layouts
- **Modal System**: Main mode for regular use, Service mode for special operations
- **Window Hints**: Fast window selection with window-hints (alt + ;)
- **Workspace Management**: Support for multiple workspaces with quick switching
- **Consistent Theme**: Tokyo Night color-inspired window gap settings

## Key Bindings

### Main Mode

| Shortcut | Action |
|----------|--------|
| `alt` + `enter` | Launch Ghostty terminal |
| `alt` + `h/j/k/l` | Focus window left/down/up/right |
| `alt` + `shift` + `h/j/k/l` | Move window left/down/up/right |
| `alt` + `/` | Toggle between horizontal/vertical tiling |
| `alt` + `,` | Toggle between horizontal/vertical accordion |
| `alt` + `f` | Toggle between floating and tiling |
| `alt` + `m` | Toggle fullscreen for focused window |
| `alt` + `-/=` | Resize window smaller/larger |
| `alt` + `1-5` | Switch to workspace 1-5 |
| `alt` + `shift` + `1-5` | Move window to workspace 1-5 |
| `alt` + `tab` | Switch between recent workspaces |
| `alt` + `shift` + `;` | Enter service mode |

### Service Mode

| Shortcut | Action |
|----------|--------|
| `esc` | Reload config and return to main mode |
| `r` | Reset workspace layout and return to main mode |
| `f` | Toggle floating layout and return to main mode |
| `backspace` | Close all windows except current and return to main mode |
| `alt` + `shift` + `h/j/k/l` | Join with window in direction and return to main mode |
| `t` | Toggle tiles/accordion layout and return to main mode |

## Window Gap Settings

The configuration has Tokyo Night theme-inspired window gaps for a visually pleasing workspace:

```toml
[gaps]
    inner.horizontal = 8  # Gap between windows horizontally
    inner.vertical   = 8  # Gap between windows vertically
    outer.left       = 10 # Gap from left screen edge
    outer.right      = 10 # Gap from right screen edge
    outer.top        = 10 # Gap from top screen edge
    outer.bottom     = 10 # Gap from bottom screen edge
```

## Installation

This configuration is installed automatically by the setup script.

For manual installation:

1. Install Aerospace using Homebrew: `brew install nikitabobko/tap/aerospace`
2. Ensure the config directory exists: `mkdir -p ~/.config/aerospace`
3. Symlink the configuration: `ln -sf ~/dotfiles/config/aerospace/aerospace.toml ~/.config/aerospace/aerospace.toml`
4. Start Aerospace: `aerospace`

## Customization

To customize further:

1. Edit `~/dotfiles/config/aerospace/aerospace.toml`
2. Use the service mode and press `esc` to reload the configuration

## Resources

- [Aerospace Documentation](https://nikitabobko.github.io/AeroSpace/guide)
- [Official GitHub Repository](https://github.com/nikitabobko/aerospace)