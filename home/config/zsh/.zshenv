# XDG paths are already set in ~/.zshenv
# Initialize essential paths
typeset -U path
path=(
    $HOME/.local/bin
    $HOME/bin
    /opt/homebrew/bin
    /opt/homebrew/sbin
    /usr/local/bin
    /usr/bin
    /bin
    /usr/sbin
    /sbin
    $path
)


# Base environment settings
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export EDITOR="nvim"
export VISUAL="$EDITOR"
export PAGER="less"
export LESS="-R"

# XDG paths are already set in ~/.zshenv
export ZDOTDIR="${XDG_CONFIG_HOME}/zsh"

# Set XDG cache/state paths for ZSH
export ZSH_CACHE_DIR="${XDG_CACHE_HOME}/zsh"
export HISTFILE="${XDG_STATE_HOME}/zsh/history"


# Ensure cache directory exists
[[ -d $ZSH_CACHE_DIR ]] || mkdir -p $ZSH_CACHE_DIR