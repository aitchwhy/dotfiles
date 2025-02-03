# ~/dotfiles/home/zsh/env.zsh - Environment variables
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export MANPAGER="sh -c 'col -bx | bat --language=man --plain'"

export LESS="-R --mouse -Dd+r$Du+b"
export LESSHISTFILE="${XDG_STATE_HOME}/less/history"
export LESSHISTSIZE=1000

# FZF configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# Zoxide configuration
export _ZO_DATA_DIR="${XDG_DATA_HOME}/zoxide"
