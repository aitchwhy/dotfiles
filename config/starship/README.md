# Starship Configuration

A sleek, informative shell prompt configuration with Tokyo Night theme for enhanced productivity and aesthetics.

## Overview

This Starship configuration provides a powerful, customized prompt with:

- Tokyo Night theme integration
- Right-side time and battery information
- Optimized scanning for fast performance
- Custom icons and segment styling
- Directory and Git status information
- Language version indicators

## Features

- 🎨 **Tokyo Night Theme**: Consistent color scheme with the rest of the environment
- ⏱️ **Right-side Information**: Time and battery displayed on the right side
- 🚀 **Performance Optimized**: Fast scanning timeout for responsive prompts
- 📂 **Directory Icons**: Custom icons for common directories
- 🔄 **Git Integration**: Branch and status information with symbols
- 💻 **Language Support**: Display runtime versions for multiple languages
- 🔋 **Battery Status**: Battery level and charging indicators

## Prompt Segments

The prompt is organized with the following segments:

1. **Left Prompt**:
   - Decorative prompt start indicator
   - Current directory with custom icons
   - Git branch and status
   - Programming language environments (Node.js, Rust, Go, PHP)
   - Time display

2. **Right Prompt**:
   - Time indicator
   - Battery status

3. **Second Line**:
   - Command success/error indicator

## Customizations

### Color Palette

The configuration uses the Tokyo Night color palette:

```toml
[palette]
# Background colors
bg = "#1a1b26"
bg_dark = "#16161e"
bg_highlight = "#292e42"
terminal_black = "#414868"

# Foreground colors
fg = "#c0caf5"
fg_dark = "#a9b1d6"
fg_gutter = "#3b4261"

# Normal colors
black = "#15161e"
red = "#f7768e"
green = "#9ece6a"
yellow = "#e0af68"
blue = "#7aa2f7"
magenta = "#bb9af7"
cyan = "#7dcfff"
white = "#a9b1d6"
```

### Directory Customization

Custom icons for common directories:

```toml
[directory.substitutions]
"Documents" = "󰈙 "
"Downloads" = " "
"Music" = " "
"Pictures" = " "
```

### Performance Optimizations

The configuration is optimized for performance:

```toml
scan_timeout = 10  # Fast scanning for responsive prompt
add_newline = false  # Clean look without extra newlines
```

### Git Integration

Git status is shown with custom formatting:

```toml
[git_branch]
symbol = ""
truncation_length = 20

[git_status]
format = '[[($all_status$ahead_behind)](fg:#769ff0 bg:#394260)]($style)'
```

## Installation

This configuration is installed automatically by the setup.sh script.

For manual installation:

1. Install Starship: `brew install starship`
2. Create the configuration directory: `mkdir -p ~/.config/starship`
3. Symlink the configuration:
   ```bash
   ln -sf ~/dotfiles/config/starship/starship.toml ~/.config/starship/starship.toml
   ln -sf ~/dotfiles/config/starship/themes ~/.config/starship/themes
   ```
4. Add Starship initialization to your shell's config file:
   ```bash
   # For ZSH (add to ~/.zshrc)
   eval "$(starship init zsh)"
   
   # For Bash (add to ~/.bashrc)
   eval "$(starship init bash)"
   ```

## Customization

To customize the configuration:

1. Edit `~/dotfiles/config/starship/starship.toml` for prompt layout and behavior
2. Edit `~/dotfiles/config/starship/themes/tokyo-night.toml` for color adjustments

## Themes

The configuration includes the following theme:

- **Tokyo Night**: A dark, visually pleasing theme that matches the Tokyo Night color scheme used throughout the system

## Resources

- [Starship Documentation](https://starship.rs/config/)
- [Starship Presets](https://starship.rs/presets/)
- [Tokyo Night Theme](https://github.com/folke/tokyonight.nvim)
- [Nerd Fonts](https://www.nerdfonts.com/) (required for icons)