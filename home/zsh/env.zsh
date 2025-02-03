# Environment variables
export EDITOR='nvim'
export VISUAL='nvim'
export MANPAGER='bat -l man -p'

# History config
export HISTFILE=~/.zsh_history
export HISTSIZE=100000
export SAVEHIST=100000

# FZF configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# Zoxide (smarter cd)
eval "$(zoxide init zsh)"
export _ZO_DATA_DIR="$HOME/.local/share/zoxide"