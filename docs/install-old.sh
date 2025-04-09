#!/usr/bin/env bash
# macOS Dotfiles Bootstrap Script
# Sets up a complete macOS environment with dotfiles, apps, and preferences

set -euo pipefail

# -----------------------------------------------------------------------------
# Environment Configuration
# -----------------------------------------------------------------------------
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
export ZDOTDIR="${ZDOTDIR:-$DOTFILES/config/zsh}"

# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------
log() { printf "%b\n" "$*" >&2; }
info() { log "\033[34m[INFO]\033[0m $*"; }
warn() { log "\033[33m[WARN]\033[0m $*"; }
error() { log "\033[31m[ERROR]\033[0m $*"; }
success() { log "\033[32m[OK]\033[0m $*"; }

# System detection
is_macos() { [[ "$OSTYPE" == darwin* ]]; }
is_apple_silicon() { [[ "$(uname -m)" == "arm64" ]]; }
has_command() { command -v "$1" >/dev/null 2>&1; }

# File operations
backup_file() {
  local file="$1"
  local backup="${file}.backup-$(date +%Y%m%d_%H%M%S)"

  if [[ -e "$file" ]]; then
    info "Backing up $file to $backup"
    mv "$file" "$backup"
  fi
}

make_link() {
  local src_orig="$1"
  local dst_symlink="$2"

  if [[ ! -e "$src_orig" ]]; then
    error "Source does not exist: $src_orig"
    return 1
  fi

  # Create parent directory if it doesn't exist
  local dst_dir=$(dirname "$dst_symlink")
  if [[ ! -d "$dst_dir" ]]; then
    info "Creating directory: $dst_dir"
    mkdir -p "$dst_dir"
  fi

  # Backup existing files
  if [[ -e "$dst_symlink" && ! -L "$dst_symlink" ]]; then
    backup_file "$dst_symlink"
  fi

  info "Linking $src_orig → $dst_symlink"
  ln -sf "$src_orig" "$dst_symlink"
}

ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    info "Creating directory: $dir"
    mkdir -p "$dir"
  fi
}

# -----------------------------------------------------------------------------
# Homebrew Setup
# -----------------------------------------------------------------------------
setup_homebrew() {
  info "Setting up Homebrew..."

  if ! has_command brew; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if is_apple_silicon; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  else
    info "Homebrew is already installed"
  fi

  # Update Homebrew
  info "Updating Homebrew..."
  brew update

  # Install from Brewfile
  if [[ -f "$DOTFILES/Brewfile" ]]; then
    info "Installing packages from Brewfile..."
    brew bundle install --file="$DOTFILES/Brewfile" --no-lock
  else
    warn "Brewfile not found at $DOTFILES/Brewfile"
  fi
}

# -----------------------------------------------------------------------------
# ZSH Setup
# -----------------------------------------------------------------------------
setup_zsh() {
  info "Setting up ZSH configuration..."
  ensure_dir "$ZDOTDIR"

  # Setup .zshenv in home directory
  local zshenv="$HOME/.zshenv"
  info "Setting up .zshenv at $zshenv"

  cat >"$zshenv" <<EOF
# Minimal stub for Zsh
export ZDOTDIR="$ZDOTDIR"
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
EOF
  success "Created $zshenv pointing to $ZDOTDIR"

  # Make sure ZSH config files are linked
  if [[ -d "$DOTFILES/config/zsh" ]]; then
    make_link "$DOTFILES/config/zsh/.zshrc" "$ZDOTDIR/.zshrc"
    make_link "$DOTFILES/config/zsh/.zprofile" "$ZDOTDIR/.zprofile"
    make_link "$DOTFILES/config/zsh/.zshenv" "$ZDOTDIR/.zshenv"
    make_link "$DOTFILES/config/zsh/aliases.zsh" "$ZDOTDIR/aliases.zsh"
    make_link "$DOTFILES/config/zsh/functions.zsh" "$ZDOTDIR/functions.zsh"
    make_link "$DOTFILES/config/zsh/fzf.zsh" "$ZDOTDIR/fzf.zsh"
  else
    error "ZSH config directory not found at $DOTFILES/config/zsh"
  fi
}

# -----------------------------------------------------------------------------
# CLI Tools Configuration
# -----------------------------------------------------------------------------
setup_tools() {
  info "Setting up CLI tools configuration..."

  # Ghostty terminal
  if [[ -f "$DOTFILES/config/ghostty/config" ]]; then
    ensure_dir "$XDG_CONFIG_HOME/ghostty"
    make_link "$DOTFILES/config/ghostty/config" "$XDG_CONFIG_HOME/ghostty/config"
  fi

  # Neovim
  if [[ -d "$DOTFILES/config/nvim" ]]; then
    ensure_dir "$XDG_CONFIG_HOME/nvim"
    make_link "$DOTFILES/config/nvim/init.lua" "$XDG_CONFIG_HOME/nvim/init.lua"

    # Link Neovim config files recursively
    if has_command find; then
      find "$DOTFILES/config/nvim/lua" -type f -name "*.lua" | while read -r file; do
        relative_path="${file#$DOTFILES/config/nvim/}"
        target_dir="$(dirname "$XDG_CONFIG_HOME/nvim/$relative_path")"
        ensure_dir "$target_dir"
        make_link "$file" "$XDG_CONFIG_HOME/nvim/$relative_path"
      done
    fi
  fi

  # Starship prompt
  make_link "$DOTFILES/config/starship.toml" "$XDG_CONFIG_HOME/starship.toml"

  # Atuin shell history
  ensure_dir "$XDG_CONFIG_HOME/atuin"
  make_link "$DOTFILES/config/atuin/config.toml" "$XDG_CONFIG_HOME/atuin/config.toml"

  # Bat (cat replacement)
  ensure_dir "$XDG_CONFIG_HOME/bat"
  make_link "$DOTFILES/config/bat/config" "$XDG_CONFIG_HOME/bat/config"

  # Zellij terminal multiplexer
  ensure_dir "$XDG_CONFIG_HOME/zellij"
  make_link "$DOTFILES/config/zellij/config.yml" "$XDG_CONFIG_HOME/zellij/config.yml"

  # Espanso text expander
  if [[ -f "$DOTFILES/config/espanso/match/base.yml" ]]; then
    ensure_dir "$XDG_CONFIG_HOME/espanso/match"
    ensure_dir "$XDG_CONFIG_HOME/espanso/config"
    make_link "$DOTFILES/config/espanso/match/base.yml" "$XDG_CONFIG_HOME/espanso/match/base.yml"
    make_link "$DOTFILES/config/espanso/config/default.yml" "$XDG_CONFIG_HOME/espanso/config/default.yml"
  fi

  info "Setting up GUI applications configuration..."

  # Karabiner (keyboard customization)
  ensure_dir "$XDG_CONFIG_HOME/karabiner"
  make_link "$DOTFILES/config/karabiner/karabiner.json" "$XDG_CONFIG_HOME/karabiner/karabiner.json"

  # VS Code
  ensure_dir "$HOME/Library/Application Support/Code/User"
  make_link "$DOTFILES/config/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
  make_link "$DOTFILES/config/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"

  # Cursor (VS Code-based editor)
  ensure_dir "$HOME/Library/Application Support/Cursor/User"
  make_link "$DOTFILES/config/cursor/settings.json" "$HOME/Library/Application Support/Cursor/User/settings.json"
  make_link "$DOTFILES/config/cursor/keybindings.json" "$HOME/Library/Application Support/Cursor/User/keybindings.json"

  # Hammerspoon
  ensure_dir "$HOME/.hammerspoon"
  make_link "$DOTFILES/config/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"

  # Claude Desktop
  ensure_dir "$HOME/Library/Application Support/Claude"
  make_link "$DOTFILES/config/ai/claude/claude_desktop_config.json" "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
}

# -----------------------------------------------------------------------------
# Development Environment Setup
# -----------------------------------------------------------------------------
setup_dev_environment() {
  info "Setting up development environment..."

  # Ensure development directories exist
  ensure_dir "$HOME/src"
  ensure_dir "$HOME/go/bin"

  # Setup git config if not already configured
  if [[ ! -f "$HOME/.gitconfig" ]]; then
    info "Setting up initial Git configuration..."

    local git_name git_email
    read -p "Enter your Git name: " git_name
    read -p "Enter your Git email: " git_email

    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    git config --global init.defaultBranch main
    git config --global core.editor "$(which nvim || which vim)"
    git config --global pull.rebase true

    success "Git configured"
  fi

  # Install or update developer tools
  if has_command pyenv; then
    info "Setting up Python environment with pyenv..."
    pyenv install --skip-existing 3.11
    pyenv global 3.11
  fi

  if has_command fnm; then
    info "Setting up Node.js environment with fnm..."
    fnm install --lts
    fnm default lts-latest
  fi
}

# -----------------------------------------------------------------------------
# Main Setup Function
# -----------------------------------------------------------------------------
main() {
  info "Starting dotfiles setup for macOS..."

  # Check if running on macOS
  if ! is_macos; then
    error "This script is designed for macOS only."
    exit 1
  fi

  # Create XDG directories
  ensure_dir "$XDG_CONFIG_HOME"
  ensure_dir "$XDG_CACHE_HOME"
  ensure_dir "$XDG_DATA_HOME"
  ensure_dir "$XDG_STATE_HOME"

  # Setup components
  setup_zsh
  setup_homebrew
  setup_tools
  setup_macos_preferences
  # setup_dev_environment

  success "Dotfiles setup complete! 🎉"
  info "Please log out and log back in, or restart your computer for all changes to take effect."
  info "To finish setting up your shell, run: exec zsh"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

# ###############
#
# # Create XDG directories
# ensure_dir "$XDG_CONFIG_HOME"
# ensure_dir "$XDG_CACHE_HOME"
# ensure_dir "$XDG_DATA_HOME"
#
# # Setup minimal .zshenv
# setup_zshenv() {
#   local zshenv="$HOME/.zshenv"
#   info "Setting up .zshenv at $zshenv"
#
#   cat >"$zshenv" <<EOF
# # Minimal stub for Zsh
# export ZDOTDIR="$ZDOTDIR"
# [[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
# EOF
#
#   success "Created $zshenv pointing to $ZDOTDIR"
# }
#
# function setup_cli() {
#   # Setup ZSH
#
#   make_link "$DOTFILES/config/starship.toml" "$XDG_CONFIG_HOME/starship.toml"
#
#   ensure_dir "$XDG_CONFIG_HOME/atuin"
#   make_link "$DOTFILES/config/atuin/config.toml" "$XDG_CONFIG_HOME/atuin"
#
#   ensure_dir "$XDG_CONFIG_HOME/bat"
#   make_link "$DOTFILES/config/bat/config" "$XDG_CONFIG_HOME/bat/config"
#
#   ensure_dir "$XDG_CONFIG_HOME/zellij"
#   make_link "$DOTFILES/config/zellij/config.yml" "$XDG_CONFIG_HOME/zellij/config.yml"
#
#   ensure_dir "$XDG_CONFIG_HOME/karabiner"
#   make_link "$DOTFILES/config/karabiner/karabiner.json" "$XDG_CONFIG_HOME/karabiner/karabiner.json"
#
#   make_link "$DOTFILES/config/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
#   make_link "$DOTFILES/config/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
#
#   make_link "$DOTFILES/config/cursor/settings.json" "$HOME/Library/Application Support/Cursor/User/settings.json"
#   make_link "$DOTFILES/config/cursor/keybindings.json" "$HOME/Library/Application Support/Cursor/User/keybindings.json"
#
#   ensure_dir "$HOME/.hammerspoon"
#   make_link "$DOTFILES/config/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"
#
#   # ensure_dir "$HOME/.hammerspoon"
#   make_link "$DOTFILES/config/ai/claude/claude_desktop_config.json" "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
#
# }
#
#
#
#
#
# main() {
#   info "Starting minimal ZSH bootstrap..."
#
#   setup_zshenv
#
# # Install Homebrew and packages
# # ensure_homebrew
# # brew_bundle "$@"
#
#   success "Bootstrap complete! Please restart your shell or run 'exec zsh'"
# }
#
# setup_zshenv
#
# main "$@"
#
#
# ##################
# #
# # setup_zshenv
# # make_link "$DOTFILES/config/zsh" "$ZDOTDIR"
# #
# # function setup_brew() {
# # }
# #
# # function setup_shell() {
# #   make_link "$DOTFILES/config/starship.toml" "$XDG_CONFIG_HOME/starship.toml"
# #   make_link "$DOTFILES/config/atuin" "$XDG_CONFIG_HOME/atuin"
# #   make_link "$DOTFILES/config/bat/config" "$XDG_CONFIG_HOME/bat/config"
# #   make_link "$DOTFILES/config/zellij/config.yml" "$XDG_CONFIG_HOME/zellij/config.yml"
# # }
# #
# # DOTFILES_CONFIG="$DOTFILES/config"
# #
# # DOTFILES_ZSH
# #
# # declare -A DOTFILE_TO_SYMLINK_MAP=(
# #   ["zsh/.zshrc"]=".zshrc"
# #   ["zsh/.zprofile"]=".zprofile"
# #   ["zsh/aliases.zsh"]="$ZDOTDIR/aliases.zsh"
# #   ["zsh/functions.zsh"]="$ZDOTDIR/functions.zsh"
# #   ["zsh/fzf.zsh"]="$ZDOTDIR/fzf.zsh"
# #
# #   ["$DOTFILES/nvim"]="$ZDOTDIR/nvim"
# #   ["$DOTFILES/nvim"]="$ZDOTDIR/nvim"
# # )
# #
# # info "Starting dotfiles installation..."
#
# #########################
#
# # info "Starting dotfiles installation..."
#
# # make_link "$DOTFILES/config/zsh/.zshrc" "$ZDOTDIR/.zshrc"
# # make_link "$DOTFILES/config/zsh/.zprofile" "$ZDOTDIR/.zprofile"
# # make_link "$DOTFILES/config/zsh/aliases.zsh" "$ZDOTDIR/aliases.zsh"
# # make_link "$DOTFILES/config/zsh/functions.zsh" "$ZDOTDIR/functions.zsh"
# # make_link "$DOTFILES/config/zsh/fzf.zsh" "$ZDOTDIR/fzf.zsh"
#
# # make_link "$DOTFILES/Brewfile" "$HOME/.Brewfile"
#
# # ensure_dir "$XDG_CONFIG_HOME/ghostty"
# # make_link "$DOTFILES/config/ghostty/config" "$XDG_CONFIG_HOME/ghostty/config"
#
# # Development tools
# # ensure_dir "$XDG_CONFIG_HOME/nvim"
# # make_link "$DOTFILES/config/nvim/init.lua" "$XDG_CONFIG_HOME/nvim/init.lua"
# # make_link "$DOTFILES/config/nvim/lazyvim.json" "$XDG_CONFIG_HOME/nvim/lazyvim.json"
# # make_link "$DOTFILES/config/nvim/lazy-lock.json" "$XDG_CONFIG_HOME/nvim/lazy-lock.json"
# # make_link "$DOTFILES/config/nvim/README.md" "$XDG_CONFIG_HOME/nvim/README.md"
# # make_link "$DOTFILES/config/nvim/lua/lazy-lock.json" "$XDG_CONFIG_HOME/nvim/lazy-lock.json"
#
# # Recursively link all lua files while preserving directory structure
# # find "$DOTFILES/config/nvim/lua" -type f -name "*.lua" | while read -r file; do
# #   relative_path="${file#$DOTFILES/config/nvim/}"
# #   target_dir="$(dirname "$XDG_CONFIG_HOME/nvim/$relative_path")"
# #   ensure_dir "$target_dir"
# #   make_link "$file" "$XDG_CONFIG_HOME/nvim/$relative_path"
# # done
#
# # make_link "$DOTFILES/config/starship.toml" "$XDG_CONFIG_HOME/starship.toml"
# # make_link "$DOTFILES/config/atuin" "$XDG_CONFIG_HOME/atuin"
# # make_link "$DOTFILES/config/bat/config" "$XDG_CONFIG_HOME/bat/config"
# # make_link "$DOTFILES/config/zellij/config.yml" "$XDG_CONFIG_HOME/zellij/config.yml"
#
# # ensure_dir "$XDG_CONFIG_HOME/espanso"
# # ensure_dir "$XDG_CONFIG_HOME/espanso/match"
# # ensure_dir "$XDG_CONFIG_HOME/espanso/config"
# # make_link "$DOTFILES/config/espanso/match/base.yml" "$XDG_CONFIG_HOME/espanso/match/base.yml"
# # make_link "$DOTFILES/config/espanso/config/default.yml" "$XDG_CONFIG_HOME/espanso/config/default.yml"
#
