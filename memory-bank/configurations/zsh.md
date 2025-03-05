# ZSH Configuration

Reference guide for my ZSH configuration structure, settings, and customizations.

## Configuration Structure

My ZSH configuration is organized modularly across several files:

| File | Purpose |
|------|---------|
| `.zshenv` | Environment variables, always loaded first |
| `.zprofile` | Login shell configuration (PATH, etc.) |
| `.zshrc` | Interactive shell configuration, plugins |
| `aliases.zsh` | Custom aliases and shortcuts |
| `functions.zsh` | Custom shell functions |
| `brew.zsh` | Homebrew-specific configurations |
| `git.zsh` | Git-specific aliases and functions |
| `nodejs.zsh` | Node.js environment configuration |
| `python.zsh` | Python environment configuration |
| `rust.zsh` | Rust environment configuration |
| `system.zsh` | System-specific configurations |
| `symlinks.zsh` | Symlink management and related functions |
| `fzf.zsh` | Fuzzy finder configuration |

## Key Environment Variables

```zsh
# XDG Base Directory specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# Default applications
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export BROWSER="open"

# History configuration
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export HISTSIZE=10000
export SAVEHIST=10000
```

## Essential Plugins

| Plugin | Purpose |
|--------|---------|
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter directory navigation |
| [starship](https://starship.rs) | Cross-shell prompt customization |
| [fzf](https://github.com/junegunn/fzf) | Command-line fuzzy finder |
| [atuin](https://github.com/ellie/atuin) | Shell history sync and search |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Fish-like autosuggestions |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | Syntax highlighting for shell commands |
| [zsh-abbr](https://github.com/olets/zsh-abbr) | Fish-like abbreviation management |

## Core ZSH Options

```zsh
# Load completion system
autoload -Uz compinit && compinit

# History options
setopt EXTENDED_HISTORY       # Save timestamp in history
setopt HIST_VERIFY            # Show command before executing history
setopt HIST_IGNORE_DUPS       # Don't save duplicates
setopt HIST_IGNORE_SPACE      # Don't save commands starting with space
setopt SHARE_HISTORY          # Share history between sessions
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks

# Directory options
setopt AUTO_CD                # cd by typing directory name
setopt AUTO_PUSHD             # Push directories to stack
setopt PUSHD_IGNORE_DUPS      # Don't push duplicates to stack

# Completion options
setopt COMPLETE_IN_WORD       # Complete from within words
setopt ALWAYS_TO_END          # Move cursor to end after completion

# Misc options
setopt INTERACTIVE_COMMENTS   # Allow comments in interactive shell
setopt NO_BEEP                # Disable beeps
setopt PROMPT_SUBST           # Allow substitution in prompt
```

## Key Aliases

```zsh
# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cd..='cd ..'
alias ~='cd ~'

# List files
alias ls='ls -G'
alias la='ls -la'
alias ll='ls -l'
alias lh='ls -lh'

# Directory operations
alias md='mkdir -p'
alias rd='rmdir'

# File operations
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# Editors
alias v='nvim'
alias vim='nvim'

# git
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gco='git checkout'
alias gd='git diff'
alias gl='git log'
alias gp='git push'
alias gpull='git pull'

# Utilities
alias cat='bat'
alias grep='rg'
alias find='fd'
alias top='btop'
```

## Custom Functions

```zsh
# Create directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
  if [ -f $1 ]; then
    case $1 in
      *.tar.bz2)   tar xjf $1     ;;
      *.tar.gz)    tar xzf $1     ;;
      *.bz2)       bunzip2 $1     ;;
      *.rar)       unrar e $1     ;;
      *.gz)        gunzip $1      ;;
      *.tar)       tar xf $1      ;;
      *.tbz2)      tar xjf $1     ;;
      *.tgz)       tar xzf $1     ;;
      *.zip)       unzip $1       ;;
      *.Z)         uncompress $1  ;;
      *.7z)        7z x $1        ;;
      *)           echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Quick find file
ff() {
  find . -name "*$1*"
}

# Quick find text in files
ft() {
  grep -r "$1" .
}
```

## Performance Tips

- Use `zprof` to profile ZSH startup time
- Lazy-load heavy environments (Python, Node.js, etc.)
- Minimize plugins that run on every command
- Use `async` loading where possible
- Keep completion caches up to date

## Troubleshooting

If experiencing slow startup:

1. Check which files are taking longest to load:
   ```
   for i in ~/.zshrc ~/.zprofile ~/.zshenv config/zsh/*.zsh; do
     time zsh -i -c "source $i; exit"
   done
   ```

2. Identify slow plugins:
   ```zsh
   # Add this to the top of .zshrc
   zmodload zsh/zprof
   
   # Add this to the bottom of .zshrc
   zprof
   ```

3. Common culprits:
   - Slow completion initialization
   - Auto-loading large environments
   - Too many plugins loaded at startup
   - Complex prompt calculations

## Useful Resources

- [ZSH Documentation](https://zsh.sourceforge.io/Doc/)
- [Starship Documentation](https://starship.rs/config/)
- [Oh My ZSH](https://ohmyz.sh/) (Reference for plugin ideas)
