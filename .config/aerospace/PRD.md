# Aerospace Configuration Requirements

This document captures the requirements, preferences, and design principles for the Aerospace window manager configuration.

## Core Requirements

### 1. Window Management

- **Tiling Layout**: Automatic window tiling
- **Accordion Layout**: Support for accordion layout
- **Floating Mode**: Toggle between tiling and floating
- **Window Gaps**: Tokyo Night-inspired window gaps
- **Window Focus**: Clear visual indication of focused window
- **Multiple Monitors**: Proper multi-monitor support
- **Window Movement**: Easy window repositioning
- **Window Resizing**: Simple window resizing

### 2. Workspace Management

- **Multiple Workspaces**: Support for 5+ workspaces
- **Workspace Switching**: Fast workspace switching
- **Window-to-Workspace**: Move windows between workspaces
- **Workspace Persistence**: Remember window layout per workspace
- **Named Workspaces**: Option for named workspaces

### 3. Navigation

- **Vim-style**: Vim-inspired directional navigation (h/j/k/l)
- **Window Hints**: Fast window selection with window-hints
- **Focus History**: Quick switching between recent windows
- **App Focusing**: Focus windows by application

### 4. Keyboard Control

- **Modal System**: Main mode and service mode
- **Alt-based**: Use Alt as primary modifier
- **Consistent Bindings**: Logical and consistent key bindings
- **Terminal Launch**: Quick terminal launching
- **Layout Toggling**: Easy switching between layouts

### 5. Visual Design

- **Window Gaps**: Uniform gaps between windows (8px inner, 10px outer)
- **Tokyo Night Theme**: Visual design consistent with Tokyo Night
- **Minimal Decoration**: Clean, minimal window decoration
- **Focus Indication**: Clear visual indication of focused window

### 6. Integration

- **Terminal**: Quick launch of preferred terminal (Ghostty)
- **System Tray**: Proper handling of system tray applications
- **Full-screen**: Proper handling of full-screen applications
- **Native Apps**: Compatibility with macOS native applications
- **Mouse**: Support for mouse operations

## Feature Requirements

### Essential Features

- **Window Layouts**: Multiple layout options
- **Workspace Management**: Support for multiple workspaces
- **Keyboard Navigation**: Vim-style directional control
- **Window Operations**: Move, resize, focus operations
- **Layout Toggling**: Switching between layout modes
- **Terminal Launch**: Quick terminal access
- **Window Hints**: Fast window selection

### Enhanced Features

- **Service Mode**: Secondary mode for special operations
- **Window Joining**: Join windows in specified directions
- **Mouse Integration**: Mouse follows focus option
- **Layout Memory**: Per-workspace layout memory
- **Window Rules**: Application-specific window rules
- **Startup Commands**: Commands to run at startup
- **Window Normalization**: Automatic window layout optimization

### Workflow Features

- **Fullscreen Toggle**: Toggle fullscreen mode
- **Named Workspaces**: Custom workspace names
- **Layout Reset**: Reset workspace layout
- **Close Others**: Close all windows except current
- **Monitor Control**: Move workspaces between monitors
- **Media Controls**: Integration with media keys

## Configuration Categories

1. **Core**: Essential window manager options
2. **Layouts**: Layout configuration
3. **Gaps**: Window gap settings
4. **Keybindings**: Keyboard shortcuts
5. **Modes**: Modal configuration
6. **Startup**: Startup commands
7. **Integration**: System integration options

## Key Mappings

- **Focus**: Alt + h/j/k/l
- **Move**: Alt + Shift + h/j/k/l
- **Layout Toggle**: Alt + / (tiles), Alt + , (accordion), Alt + f (floating)
- **Fullscreen**: Alt + m
- **Resize**: Alt + -/=
- **Workspaces**: Alt + 1-5
- **Move to Workspace**: Alt + Shift + 1-5
- **Quick Switch**: Alt + Tab
- **Terminal**: Alt + Enter
- **Service Mode**: Alt + Shift + ;

## Configuration Principles

1. **Simplicity**: Keep configuration simple and focused
2. **Consistency**: Consistent behavior and key bindings
3. **Performance**: Optimize for responsiveness
4. **Aesthetics**: Visual appeal with Tokyo Night theme
5. **Integration**: Seamless integration with macOS
6. **Discoverability**: Easy to discover features
7. **Reliability**: Stable and predictable behavior

## Customization Areas

1. **Gaps**: Window gap sizes
2. **Keybindings**: Keyboard shortcuts
3. **Layouts**: Layout behavior
4. **Modes**: Modal behavior
5. **Startup**: Startup commands

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
- Optimized layouts for productivity6. **Services**: Service mode operations
