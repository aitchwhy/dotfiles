# Starship Configuration Version Information

This document captures the version information and state of the Starship prompt configuration.

## Version Information

- **Starship Version**: 1.23.0
- **Last Updated**: 2025-05-03

## Dependencies

- **Core Dependencies**:
  - Zsh (5.2.37)
  - Nerd Font (installed)
  - Terminal with true color support

- **Optional Integrations**:
  - Git (2.49.0)
  - Node.js (23.11.0)
  - Rust (via rustup)
  - Python (3.12.10, 3.13.3)
  - Go (1.24.2)

## Configuration Health

- **Performance**: Fast prompt rendering (< 10ms scan time)
- **Theme**: Tokyo Night theme applied properly
- **Prompt Components**: All components displaying correctly
- **Right Prompt**: Time and battery information showing on right side

## Debug Information

- **Config Path**: ~/.config/starship/starship.toml
- **Theme Path**: ~/.config/starship/themes/tokyo-night.toml
- **Cache Path**: ~/.cache/starship
- **Log**: View with `STARSHIP_LOG=trace starship prompt`
- **Timings**: View with `STARSHIP_LOG=trace STARSHIP_TIMER=1 starship prompt`

## Command Line Tools

Commands available for Starship management:

```bash
# Print prompt explanation
starship explain

# Print module timings
STARSHIP_LOG=trace STARSHIP_TIMER=1 starship module time

# Reload Starship (by restarting shell)
exec zsh
```

## Just Integration

Just tasks available for Starship:

```
just star edit        # Edit Starship config
just star theme       # Edit Starship Tokyo Night theme
just star reload      # Reload Starship to apply changes
just star preset save # Create Starship preset from current config
just star presets     # List available Starship presets
just star apply       # Apply Starship preset
just star explain     # Show Starship configuration explanation
just star timings     # Print Starship module timings
```

## Recent Changes

- Updated to Starship 1.23.0
- Applied Tokyo Night theme
- Added right-side time and battery information
- Reduced scan timeout for faster performance
- Enhanced Git status information
- Improved directory formatting