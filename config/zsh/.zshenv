# # Set ZDOTDIR if you want to re-home Zsh.
# [[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"

# # Minimal stub for Zsh to load configs from /Users/hank/.config/zsh
# export ZDOTDIR="/Users/hank/.config/zsh"
# [[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"

####################

# XDG Base Directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# Ensure directories exist
mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"

# Core paths
export DOTFILES="$HOME/dotfiles"
export CONFIGS="$XDG_CONFIG_HOME"

# Tool configuration paths
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
export STARSHIP_CACHE="$XDG_CACHE_HOME/starship"
export ATUIN_CONFIG_DIR="$XDG_CONFIG_HOME/atuin"
export ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij"
export BAT_CONFIG_PATH="$XDG_CONFIG_HOME/bat/config"
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"

# Editor configurations
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="bat"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Language configurations
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# History configuration
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export HISTSIZE=1000000
export SAVEHIST=1000000

# Homebrew configuration
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_AUTOREMOVE=1
export HOMEBREW_NO_BOTTLE_SOURCE_FALLBACK=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
export HOMEBREW_BUNDLE_FILE="$HOME/.Brewfile"

# Additional tool configurations
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node/repl_history"
export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/startup.py"
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export AWS_CONFIG_FILE="$XDG_CONFIG_HOME/aws/config"
export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME/aws/credentials"




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
