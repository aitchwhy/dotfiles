# Aerospace Configuration Version Information

This document captures the version information and state of the Aerospace window manager configuration.

## Version Information

- **Aerospace Version**: 0.18.4-Beta
- **Last Updated**: 2025-05-03

## Dependencies

- **Core Dependencies**:
  - macOS (24.4.0)
  - Ghostty (1.1.3) or any other terminal emulator

- **Optional Dependencies**:
  - skhd (0.3.9) - For additional keyboard shortcuts
  - yabai (legacy) - For compatibility with yabai scripts

## Configuration Health

- **Performance**: Smooth window management operations
- **Key Bindings**: All key bindings working as expected
- **Layouts**: Tiling, accordion, and floating layouts working
- **Workspaces**: Multiple workspace support functional
- **Window Hints**: Window hint mode working

## Debug Information

- **Config Path**: ~/.config/aerospace/aerospace.toml
- **Log Path**: ~/Library/Logs/aerospace.log
- **Process**: Running as a background service

## Command Line Tools

Commands available for Aerospace management:

```bash
# Start Aerospace
aerospace

# Reload configuration
aerospace reload-config

# Restart Aerospace
aerospace restart

# Check status
aerospace status

# List windows
aerospace list-windows

# Focus a window
aerospace focus-window-using-selector "WINDOW_ID"

# Show window hints
aerospace focus window-hint

# Toggle floating/tiling
aerospace layout floating tiling

# Set tile layout
aerospace layout tiles

# Set accordion layout
aerospace layout accordion
```

## Just Integration

Just tasks available for Aerospace:

```
just aero edit         # Edit Aerospace config
just aero reload       # Reload Aerospace configuration
just aero restart      # Restart Aerospace
just aero status       # Check Aerospace status
just aero focus title  # Focus window by title (fuzzy)
just aero focus app    # Focus window by app
just aero windows      # List all windows
just aero hints        # Show window hints
just aero toggle-float # Toggle floating/tiling mode
just aero tile         # Tile all windows
just aero accordion    # Set accordion layout
```

## Recent Changes

- Updated to Aerospace 0.18.4-Beta
- Improved window gap settings to match Tokyo Night theme
- Enhanced key bindings for better workflow
- Added service mode for special operations
- Optimized layouts for productivity