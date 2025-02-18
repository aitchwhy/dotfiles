#!/usr/bin/env bash
# install.sh - Main installation script

set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"

source "$DOTFILES/utils.sh"

info "Starting dotfiles installation..."

# Create XDG directories
ensure_dir "$XDG_CONFIG_HOME"
ensure_dir "$XDG_CACHE_HOME"
ensure_dir "$XDG_DATA_HOME"

# Install Homebrew and packages
# ensure_homebrew
# brew_bundle "$@"

# Setup ZSH
setup_zshenv
setup_zsh

# Link configuration file
make_link "$DOTFILES_DIR/config/git/config" "$XDG_CONFIG_HOME/git/config"
make_link "$DOTFILES_DIR/config/git/ignore" "$XDG_CONFIG_HOME/git/ignore"
make_link "$DOTFILES_DIR/config/nvim" "$XDG_CONFIG_HOME/nvim"

# create_symlink "$DOTFILES/config/zsh" "$XDG_CONFIG_HOME/zsh"
create_symlink "$DOTFILES/config/zsh/.zprofile" "$XDG_CONFIG_HOME/zsh/.zprofile"
create_symlink "$DOTFILES/config/zsh/.zshrc" "$XDG_CONFIG_HOME/zsh/.zshrc"
create_symlink "$DOTFILES/config/zsh/.zshrc" "$XDG_CONFIG_HOME/zsh/.zshrc"

# Development tools
create_symlink "$DOTFILES/config/nvim" "$XDG_CONFIG_HOME/nvim"
# create_symlink "$DOTFILES/config/git" "$XDG_CONFIG_HOME/git"
create_symlink "$DOTFILES/Brewfile" "$HOME/.Brewfile"

# Terminal tools
create_symlink "$DOTFILES/config/starship/starship.toml" "$XDG_CONFIG_HOME/starship.toml"
create_symlink "$DOTFILES/config/atuin" "$XDG_CONFIG_HOME/atuin"
create_symlink "$DOTFILES/config/bat" "$XDG_CONFIG_HOME/bat"
create_symlink "$DOTFILES/config/zellij" "$XDG_CONFIG_HOME/zellij"

# macOS apps
if is_macos; then
  create_symlink "$DOTFILES/config/karabiner" "$XDG_CONFIG_HOME/karabiner"
  create_symlink "$DOTFILES/config/hammerspoon" "$HOME/.hammerspoon"

  # Handle paths with spaces
  # create_symlink "$DOTFILES/config/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
  # create_symlink "$DOTFILES/config/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
  create_symlink "$DOTFILES/config/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
  create_symlink "$DOTFILES/config/vscode/keybindings.json" "$HOME/$HOME/Library/Application Support/Code/User/keybindings.json"
  create_symlink "$DOTFILES/config/cursor/settings.json" "$HOME/Library/Application Support/Cursor/User/settings.json"
  create_symlink "$DOTFILES/config/cursor/keybindings.json" "$HOME/$HOME/Library/Application Support/Cursor/User/keybindings.json"
fi

success "Dotfiles installation complete!"
