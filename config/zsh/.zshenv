
# # ~/.zshenv
# # Minimal stub for Zsh to load configs from ~/.config/zsh
# export ZDOTDIR="/Users/hank/.config/zsh"
# [[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"

########
# Tool configurations
export LANG=en_US.UTF-8
export EDITOR="nvim"
export VISUAL="nvim"

# export XDG_CONFIG_HOME="$HOME/.config"
# export XDG_CACHE_HOME="$HOME/.cache"
# export XDG_DATA_HOME="$HOME/.local/share"
# export XDG_STATE_HOME="$HOME/.local/state"
# export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

export DOTFILES_DIR="$HOME/dotfiles"
export CONFIG="$HOME/.config"
# export ZDOTDIR="$CONFIG/zsh"

# Ensure directories exist
# mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME/zsh"

mkdir -p "$ZDOTDIR" "$CONFIG"


# # Configure tool XDG paths
export STARSHIP_CONFIG="$CONFIG/starship.toml"
export ATUIN_CONFIG_DIR="$CONFIG/atuin"
export ZELLIJ_CONFIG_DIR="$CONFIG/zellij"
export VOLTA_HOME="$HOME/.volta"

export BAT_CONFIG_PATH="$CONFIG/bat/config"
export RIPGREP_CONFIG_PATH="$CONFIG/ripgrep/config"

# History configuration
export HISTFILE="$CONFIG/zsh/history"
export HISTSIZE=10000
export SAVEHIST=10000

# Metal acceleration for ML/TensorFlow
export METAL_DEVICE_WRAPPER_TYPE=1
export TF_ENABLE_METAL=1

# Zoxide data location
export _ZO_DATA_DIR="$/zoxide"

# Homebrew
# export HOMEBREW_BUNDLE_FILE="$XDG_CONFIG_HOME/brewfile/Brewfile"
export HOMEBREW_BUNDLE_INSTALL_CLEANUP=1
export HOMEBREW_BUNDLE_DUMP_DESCRIBE=1
