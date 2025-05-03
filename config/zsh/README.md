# ZSH Configuration

A modern, feature-rich ZSH configuration with aliases, functions, and integrations optimized for macOS development.

## Overview

This ZSH configuration provides a powerful, customized shell environment with:

- Organized modular structure with separate files for different concerns
- Extensive aliases for common tasks and tools
- Powerful functions for navigation and development
- Integration with modern tools like FZF, Atuin, and Starship
- Performance optimizations for fast startup times

## Structure

The configuration is organized into several modular files:

```
~/.config/zsh/
├── aliases.zsh     # Command aliases and shortcuts
├── anterior.zsh    # Project-specific configuration
├── brew.zsh        # Homebrew-related settings
├── defaults.zsh    # Default environment variables
├── functions.zsh   # Custom ZSH functions
└── utils.zsh       # Utility functions for scripts
```

## Key Features

- **Modular Organization**: Separate files for different concerns
- **Tool Integrations**: FZF, Atuin, Starship, and more
- **Custom Aliases**: Extensive aliases for common tasks
- **Navigation Functions**: Quick directory jumping and search
- **Git Workflow**: Enhanced Git commands and shortcuts
- **Homebrew Integration**: Optimized Homebrew environment
- **Performance Optimization**: Fast startup and command execution

## Command Aliases

The configuration includes aliases for:

### File Navigation

```zsh
alias l="eza -lh --icons --git --no-quotes"
alias ll="eza -lha --icons --git --no-quotes"
alias lt="eza -lT --icons --git --no-quotes"
alias lta="eza -lTa --icons --git --no-quotes"
```

### Directory Navigation

```zsh
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
```

### Tool-specific Aliases

```zsh
# Just
alias j="just"
alias jfmt="just --unstable --fmt"

# Git
alias ga="git add"
alias gs="git status"
alias gco="git checkout"
alias gc="git commit"
alias gd="git diff"

# Neovim
alias v="nvim"
alias vi="nvim"
alias vim="nvim"
```

## Custom Functions

The configuration includes several powerful functions:

### FZF-enhanced File Search Function

```zsh
# Find files with FZF
f() {
  local result
  if [[ -n "$1" ]]; then
    # Search with specific pattern
    result=$(fd --type f --hidden --follow --exclude .git "$1" | fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}')
  else
    # Open fuzzy finder without pattern
    result=$(fd --type f --hidden --follow --exclude .git | fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}')
  fi
  
  # Open selected file in editor
  if [[ -n "$result" ]]; then
    ${EDITOR:-nvim} "$result"
  fi
}
```

### Git-enhanced Functions

```zsh
# Fuzzy search git log and copy commit hash
fgit() {
  local commits commit
  commits=$(git log --oneline --color=always | fzf --ansi --multi --preview 'git show --color=always {1}')
  
  if [[ -n "$commits" ]]; then
    commit=$(echo "$commits" | awk '{print $1}')
    echo "$commit" | tr -d '\n' | pbcopy
    echo "Copied commit: $commit"
  fi
}
```

## Environment Configuration

The setup includes optimized environment variables:

### Tool Configuration

```zsh
# FZF
export FZF_DEFAULT_OPTS='--height 40% --border --layout=reverse --marker="✓" --bind=ctrl-j:down,ctrl-k:up'

# Bat
export BAT_THEME="--theme=OneHalfDark"
export DELTA_PAGER="bat --plain --paging=never"

# Homebrew
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1

# Default editor
export EDITOR='nvim'
export VISUAL='nvim'
```

## Integration with Other Tools

This configuration integrates with:

### Command History with Atuin

```zsh
# Atuin setup
export ATUIN_WORKSPACES=true
export ATUIN_ENTER_ACCEPT=true
export ATUIN_SYNC_FREQUENCY="60m"
eval "$(atuin init zsh)"
```

### Directory Management with Zoxide

```zsh
# Zoxide for smarter cd
eval "$(zoxide init zsh)"
```

### Shell Prompt with Starship

```zsh
# Starship prompt
export STARSHIP_CONFIG=~/.config/starship/starship.toml
eval "$(starship init zsh)"
```

## Installation

This configuration is installed automatically by the setup.sh script.

For manual installation:

1. Ensure ZSH is installed: `brew install zsh`
2. Create the config directory: `mkdir -p ~/.config/zsh`
3. Symlink the configuration files:
   ```bash
   ln -sf ~/dotfiles/config/zsh ~/.config/zsh
   ```
4. Create a minimal ~/.zshenv file:
   ```bash
   echo 'export ZDOTDIR="$HOME/.config/zsh"' > ~/.zshenv
   echo 'source "$ZDOTDIR/.zshenv"' >> ~/.zshenv
   ```
5. Start a new ZSH session: `exec zsh`

## Customization

To customize the configuration:

1. Edit the appropriate file in `~/dotfiles/config/zsh/`
2. For personal aliases and functions, create a `~/.config/zsh/custom.zsh` file which will be automatically sourced if it exists

## Resources

- [ZSH Documentation](http://zsh.sourceforge.net/Doc/)
- [Starship Prompt](https://starship.rs/)
- [Atuin Shell History](https://github.com/atuinsh/atuin)
- [FZF Fuzzy Finder](https://github.com/junegunn/fzf)