# XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# Ensure directories exist
mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME/zsh"

# Tell zsh to use XDG dirs
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Tool configurations
export LANG=en_US.UTF-8
export EDITOR="nvim"
export VISUAL="nvim"

# Configure tool XDG paths
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship.toml"
export ATUIN_CONFIG_DIR="$XDG_CONFIG_HOME/atuin"
export ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij"
export BAT_CONFIG_PATH="$XDG_CONFIG_HOME/bat/config"
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"

# History configuration
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export HISTSIZE=10000
export SAVEHIST=10000

# Metal acceleration for ML/TensorFlow
export METAL_DEVICE_WRAPPER_TYPE=1
export TF_ENABLE_METAL=1

# Zoxide data location
export _ZO_DATA_DIR="$XDG_DATA_HOME/zoxide"

# Homebrew
# export HOMEBREW_BUNDLE_FILE="$XDG_CONFIG_HOME/brewfile/Brewfile"
export HOMEBREW_BUNDLE_INSTALL_CLEANUP=1
export HOMEBREW_BUNDLE_DUMP_DESCRIBE=1
