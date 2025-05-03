# Yazi Configuration Version Information

This document captures the version information and state of the Yazi configuration.

## Version Information

- **Yazi Version**: 25.4.8
- **Last Updated**: 2025-05-03

## Dependencies

- **Core Dependencies**:
  - bat (0.25.0) - For text file preview
  - eza (0.21.3) - For directory preview
  - hexyl (0.16.0) - For binary file preview
  - glow (2.1.0) - For markdown preview
  - ouch (0.6.1) - For archive handling
  - unar (latest) - For archive extraction

- **Optional Dependencies**:
  - ghostty (1.1.3) - Terminal integration
  - nvim (0.11.1) - Editor integration
  - lazygit (0.50.0) - Git integration

## Plugin Status

Installed plugins and their status:

| Plugin | Status | Description |
|--------|--------|-------------|
| full-border | Working | Adds borders to UI elements |
| mactag | Working | macOS tag integration |
| starship | Working | Starship prompt integration |
| mime-ext | Working | Enhanced MIME type detection |
| folder-rules | Working | Context-aware folder settings |
| bunny | Working | Quick directory jumping |
| copy-file-contents | Working | Enhanced copy functionality |
| smart-paste | Working | Improved paste behavior |
| jump-to-char | Working | Fast character navigation |
| projects | Working | Project management |
| rich-preview | Working | Enhanced file previews |
| vcs-files | Working | Version control integration |

## Configuration Health

- **Performance**: Fast startup and navigation
- **Preview Support**: Working for all file types
- **Integration**: Properly integrated with Neovim and other tools
- **UI**: Tokyo Night theme applied consistently

## Debug Information

- **Config Path**: ~/.config/yazi
- **Cache Path**: ~/.cache/yazi
- **Log Path**: ~/.cache/yazi/log
- **Worker Threads**: micro: 12, macro: 16

## Command Line Tools

Commands available for Yazi management:

```bash
# Start Yazi in current directory
yazi .

# Start Yazi with directory tracking
y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}
```

## Just Integration

Just tasks available for Yazi:

```
just yazi edit         # Edit Yazi config
just yazi init         # Edit Yazi Lua init file
just yazi keymap       # Edit Yazi keymap
just yazi theme        # Edit Yazi theme
just yazi plugins      # List Yazi plugins
just yazi install-plugins # Install recommended Yazi plugins
just yazi update-plugins  # Update Yazi plugins
just yazi here         # Open current directory in Yazi
just yazi home         # Open home directory in Yazi
just yazi config       # Open config directory in Yazi
```

## Recent Changes

- Updated to Yazi 25.4.8
- Optimized worker counts for Apple Silicon
- Enhanced Tokyo Night theme integration
- Improved Neovim integration
- Added macOS tag support
- Enhanced file previews