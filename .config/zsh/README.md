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

# Setup

```md
Below is a tight opinionated checklist for dialling-in each CLI tool. I’ve kept every suggestion macOS-centric, zsh-friendly and compatible with Nerd-Font terminals. Use the ”Δ” lines to spot what to add/modify in your current files; the rest of your existing config looks solid.

Tool Key wins What to change (Δ = new/replace) Why / refs
Aerospace • Keep gaps/accordion defaults – they’re tuned already
• Add window-hint mode for fast nav Δ [mode.main.binding]
hyper-; = 'focus window-hint' Gives i3-style “jump by letter” without fighting your Caps-to-Hyper layer.
Atuin (you called it fatuin) • Turn on workspace filter & “enter_accept” for instant repeat
• Sync hourly instead of every cmd Δ workspaces=true
Δ enter_accept=true
Δ auto_sync=true & sync_frequency="60m" Faster recall + less background traffic; workspace filter plays nicely with git‐root jumps.
bat • Let theme follow terminal palette
• Pipe to delta for all git pagers Δ export BAT_THEME="--theme=OneHalfDark"
Δ export DELTA_PAGER="bat --plain --paging=never" Bat now auto-detects light/dark on 0.24+; feeding it to delta keeps colour parity.
GitHub
GitHub
fzf • One env var beats wrapper scripts
• Respect tmux pop-up Δ export FZF_DEFAULT_OPTS='--height 40% --border --cycle --layout=reverse --marker="✓" --bind=ctrl-j:down,ctrl-k:up' 40 % pop-up in tmux, reverse list, consistent key-nav.
GitHub
GitHub
git • Delta already configured; just surface interactive-add
• Protect main + forbid lease-violations Δ [interactive] diffFilter = delta --color-only (you have this) ✅
Δ [push] default = current, followTags=true ✅
Δ [push] --force-with-lease = false Safe-by-default pushes, delta for git add -p.
GitHub
glow • Use rich-display in Yazi only (already done)
• Set pager to bat outside Δ export GLOW_PAGER="bat --plain --language=markdown" Uniform styling & obeys your BAT_THEME.
Homebrew • Avoid auto update in CI, keep analytics off Δ HOMEBREW_NO_AUTO_UPDATE=1 (CI only)
Δ HOMEBREW_NO_ANALYTICS=1 Faster scripted installs; privacy.
htop • Show IO & pids in 1-screen layout Open htop → F2 Configure:
Δ Add IO Read/Write after CPU columns
Δ Fields order PID USER CPU% MEM% IO_R IO_W TIME
Save → writes to ~/.config/htop/htoprc Gives instant disk choke visibility; plays well with 120-char width.
Gist
just • Turn on summary & shell-override once justfile top:
makefile<br>set summary := "on"<br>set shell := ["zsh", "-cu"]<br> Colourised “running …” banner and zsh-built-ins everywhere.
yazi • Huge config is fine; cull plugins that duplicate core (eg. smart-enter now builtin)
• Move heavy previewers to async In plugin.prepend_previewers remove: smart-enter, rich-preview (Yazi 0.2+)
Δ Add preview.max_file_size = "5MB" Snappier first load, no double-call to Lua.
starship • Use right-prompt for clock/battery
• Reduce scan latency Δ right_format = "$time$battery"
Δ scan_timeout = 10
Δ add_newline = false
Δ palette = 'tokyo-night' (already in Yazi) Keeps left prompt static; 10 ms scan is enough on M-chip.
Starship: Cross-Shell Prompt
Starship: Cross-Shell Prompt
```
