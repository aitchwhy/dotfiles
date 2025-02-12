
# # ~/.zshenv
# # Minimal stub for Zsh to load configs from ~/.config/zsh
# export ZDOTDIR="/Users/hank/.config/zsh"
# [[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"

########


# # Configure tool XDG paths
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship.toml"
export ATUIN_CONFIG_DIR="$XDG_CONFIG_HOME/atuin"
export ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij"
# export VOLTA_HOME="$HOME/.volta"
export DOTFILES_DIR="$HOME/dotfiles"

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
