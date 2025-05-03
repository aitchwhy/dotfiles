# ZSH Configuration Version Information

This document captures the version information and state of the ZSH configuration.

## Version Information

- **ZSH Version**: 5.2.37
- **Last Updated**: 2025-05-03

## Dependencies

- **Core Plugins**:
  - zsh-autosuggestions (0.7.1)
  - zsh-syntax-highlighting (0.8.0)
  - zsh-completions (0.35.0)

- **Integrated Tools**:
  - starship (1.23.0) - Prompt
  - atuin (18.5.0) - History management
  - zoxide (0.9.7) - Directory navigation
  - fzf (0.61.3) - Fuzzy finder
  - eza (0.21.3) - File listing
  - just (1.40.0) - Task runner

## Configuration Health

Shell startup performance:

```
time zsh -i -c exit
0.12s user 0.08s system 94% cpu 0.216 total
```

## Key Files

- **~/.zshenv**: Entry point, sets ZDOTDIR
- **$ZDOTDIR/.zshrc**: Main configuration
- **$ZDOTDIR/.zprofile**: Login-specific settings
- **$ZDOTDIR/aliases.zsh**: Command aliases
- **$ZDOTDIR/functions.zsh**: Custom functions
- **$ZDOTDIR/just.zsh**: Just integration
- **$ZDOTDIR/utils.zsh**: Utility functions
- **$ZDOTDIR/anterior.zsh**: Project-specific settings

## Environment Variables

```bash
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"
EDITOR="nvim"
VISUAL="nvim"
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=${HISTSIZE}
STARSHIP_CONFIG="$DOTFILES/config/starship/starship.toml"
ATUIN_CONFIG_DIR="$DOTFILES/config/atuin"
YAZI_CONFIG_DIR="$DOTFILES/config/yazi"
ZELLIJ_CONFIG_DIR="$DOTFILES/config/zellij"
```

## Debug Information

- **Completions Path**: $HOMEBREW_PREFIX/share/zsh/site-functions
- **History File**: ~/.zsh_history
- **Cache Path**: ~/.cache/zsh
- **Completion Cache**: ~/.zcompdump

## Just Integration

Just tasks available for ZSH:

```
just zsh edit           # Edit ZSH config
just zsh aliases        # Edit ZSH aliases
just zsh functions      # Edit ZSH functions
just zsh reload         # Reload ZSH config
just zsh time           # Check ZSH startup time
just zsh list-aliases   # List all ZSH aliases
just zsh list-functions # List all ZSH functions
just zsh plugins        # Install recommended ZSH plugins
just zsh update         # Check for ZSH plugin updates
```

## Recent Changes

- Updated to latest plugin versions
- Added Just integration
- Improved startup performance
- Enhanced aliases and functions
- Added tool-specific configuration sections