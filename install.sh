#!/usr/bin/env bash
# install.sh - Main installation script

# set -euo pipefail

# DOTFILES="${DOTFILES:-$HOME/dotfiles}"

export XDG CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"
# export ZDOTDIR="${ZDOTDIR:-$DOTFILES/config/zsh}"
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"

. "$DOTFILES/utils.sh"

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

make_link "$DOTFILES/config/zsh/.zshrc" "$ZDOTDIR/.zshrc"
make_link "$DOTFILES/config/zsh/.zprofile" "$ZDOTDIR/.zprofile"
make_link "$DOTFILES/config/zsh/aliases.zsh" "$ZDOTDIR/aliases.zsh"
make_link "$DOTFILES/config/zsh/functions.zsh" "$ZDOTDIR/functions.zsh"
make_link "$DOTFILES/config/zsh/fzf.zsh" "$ZDOTDIR/fzf.zsh"

make_link "$DOTFILES/Brewfile" "$HOME/.Brewfile"

ensure_dir "$XDG_CONFIG_HOME/ghostty"
make_link "$DOTFILES/config/ghostty/config" "$XDG_CONFIG_HOME/ghostty/config"

# Link configuration file
make_link "$DOTFILES/config/git/gitconfig" "$HOME/.gitconfig"
make_link "$DOTFILES/config/git/gitignore" "$HOME/.gitignore"

# ensure_dir "$ZDOTDIR"
# setup_zshenv

# Development tools
ensure_dir "$XDG_CONFIG_HOME/nvim"
make_link "$DOTFILES/config/nvim/init.lua" "$XDG_CONFIG_HOME/nvim/init.lua"
make_link "$DOTFILES/config/nvim/lazyvim.json" "$XDG_CONFIG_HOME/nvim/lazyvim.json"
make_link "$DOTFILES/config/nvim/lazy-lock.json" "$XDG_CONFIG_HOME/nvim/lazy-lock.json"
make_link "$DOTFILES/config/nvim/README.md" "$XDG_CONFIG_HOME/nvim/README.md"

# Recursively link all lua files while preserving directory structure
find "$DOTFILES/config/nvim/lua" -type f -name "*.lua" | while read -r file; do
  relative_path="${file#$DOTFILES/config/nvim/}"
  target_dir="$(dirname "$XDG_CONFIG_HOME/nvim/$relative_path")"
  ensure_dir "$target_dir"
  make_link "$file" "$XDG_CONFIG_HOME/nvim/$relative_path"
done

make_link "$DOTFILES/config/starship.toml" "$XDG_CONFIG_HOME/starship.toml"
make_link "$DOTFILES/config/atuin" "$XDG_CONFIG_HOME/atuin"
make_link "$DOTFILES/config/bat/config" "$XDG_CONFIG_HOME/bat/config"
make_link "$DOTFILES/config/zellij/config.yml" "$XDG_CONFIG_HOME/zellij/config.yml"

ensure_dir "$XDG_CONFIG_HOME/espanso"
ensure_dir "$XDG_CONFIG_HOME/espanso/match"
ensure_dir "$XDG_CONFIG_HOME/espanso/config"
make_link "$DOTFILES/config/espanso/match/base.yml" "$XDG_CONFIG_HOME/espanso/match/base.yml"
make_link "$DOTFILES/config/espanso/config/default.yml" "$XDG_CONFIG_HOME/espanso/config/default.yml"

# macOS apps
if is_macos; then

  ensure_dir "$XDG_CONFIG_HOME/karabiner"
  make_link "$DOTFILES/config/karabiner/karabiner.json" "$XDG_CONFIG_HOME/karabiner/karabiner.json"

  ensure_dir "$HOME/.hammerspoon"
  make_link "$DOTFILES/config/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"

  make_link "$DOTFILES/config/ai/claude/claude_desktop_config.json" "$HOME/Library/Application Support/Claude/claude_desktop_config.json"

  # Handle paths with spaces
  # create_symlink "$DOTFILES/config/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
  # create_symlink "$DOTFILES/config/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
  make_link "$DOTFILES/config/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
  make_link "$DOTFILES/config/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
  make_link "$DOTFILES/config/cursor/settings.json" "$HOME/Library/Application Support/Cursor/User/settings.json"
  make_link "$DOTFILES/config/cursor/keybindings.json" "$HOME/Library/Application Support/Cursor/User/keybindings.json"

fi

success "Dotfiles installation complete!"
