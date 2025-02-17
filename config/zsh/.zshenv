# # Set ZDOTDIR if you want to re-home Zsh.
# [[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"

# # Minimal stub for Zsh to load configs from /Users/hank/.config/zsh
# export ZDOTDIR="/Users/hank/.config/zsh"
# [[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"

####################

# # XDG Base Directories
# export XDG_CONFIG_HOME="$HOME/.config"
# export XDG_CACHE_HOME="$HOME/.cache"
# export XDG_DATA_HOME="$HOME/.local/share"
# export XDG_STATE_HOME="$HOME/.local/state"
# export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

############################

# # XDG Base Directory
# export XDG_CONFIG_HOME="$HOME/.config"
# export XDG_DATA_HOME="$HOME/.local/share"
# export XDG_STATE_HOME="$HOME/.local/state"
# export XDG_CACHE_HOME="$HOME/.cache"
#
# # Path Configuration
# typeset -U path PATH
# path=(
#     $HOME/.local/bin
#     $HOME/bin
#     /opt/homebrew/bin
#     /opt/homebrew/sbin
#     $path
# )
# export PATH
