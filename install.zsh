#!/usr/bin/env zsh
# ========================================================================
# install.zsh - macOS dotfiles installation script
# ========================================================================
# This script handles the installation and setup of the dotfiles repository.
# It creates necessary directories, symlinks configuration files, installs
# packages, and configures system preferences.

set -euo pipefail

# ========================================================================
# Source Utility Functions
# ========================================================================

# Determine DOTFILES path and utils location
# export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
# export UTILS_PATH="$DOTFILES/config/zsh/utils.zsh"

# # Source utils.zsh if available, or define minimal required functions for bootstrapping
# if [[ -f "$UTILS_PATH" ]]; then
#   source "$UTILS_PATH"
# else
#   # Define minimal required utility functions for bootstrapping
#   has_command() { command -v "$1" >/dev/null 2>&1; }
#   # Colored output
#   log_info() { printf '\033[0;34m[INFO]\033[0m %s\n' "$*"; }
#   log_success() { printf '\033[0;32m[SUCCESS]\033[0m %s\n' "$*"; }
#   log_warn() { printf '\033[0;33m[WARNING]\033[0m %s\n' "$*" >&2; }
#   log_error() { printf '\033[0;31m[ERROR]\033[0m %s\n' "$*" >&2; }

# # Source utils.zsh if available, or define minimal required functions for bootstrapping
# if [[ -f "$UTILS_PATH" ]]; then
#   source "$UTILS_PATH"
# else
#   # Define minimal required utility functions for bootstrapping
#   has_command() { command -v "$1" >/dev/null 2>&1; }
#   # Colored output
#   log_info() { printf '\033[0;34m[INFO]\033[0m %s\n' "$*"; }
#   log_success() { printf '\033[0;32m[SUCCESS]\033[0m %s\n' "$*"; }
#   log_warn() { printf '\033[0;33m[WARNING]\033[0m %s\n' "$*" >&2; }
#   log_error() { printf '\033[0;31m[ERROR]\033[0m %s\n' "$*" >&2; }
#
#   # Directory operations
#   ensure_dir() {
#     local dir="$1"
#     if [[ ! -d "$dir" ]]; then
#       mkdir -p "$dir"
#       log_success "Created directory: $dir"
#     fi
#   }
#
#   # System detection
#   is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }
#   is_apple_silicon() { [[ "$(uname -m)" == "arm64" ]]; }
#
#   # Aliases for different naming conventions
#   info() { log_info "$@"; }
#   success() { log_success "$@"; }
#   warn() { log_warn "$@"; }
#   error() { log_error "$@"; }
#
#   # Define required XDG environment variables if we can't load utils.zsh
#   export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
#   export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
#   export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
#   export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
#   export ZDOTDIR_TARGET="$XDG_CONFIG_HOME/zsh"
#   export ZDOTDIR_SRC="$DOTFILES/config/zsh"
#   export BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
# fi

# Check system requirements
function check_requirements() {
  info "Checking system requirements..."

  # Check if running on macOS
  if ! is_macos; then
    error "This configuration is designed for macOS."
    return 1
  fi

  # Check for required commands
  local required_commands=(
    "git"
    "curl"
    "zsh"
  )

  local missing_commands=()
  for cmd in "${required_commands[@]}"; do
    if ! has_command "$cmd"; then
      missing_commands+=("$cmd")
    fi
  done

  if ((${#missing_commands[@]} > 0)); then
    error "Required commands not found: ${missing_commands[*]}"
    return 1
  fi

  success "System requirements met"
  return 0
}

#   # System detection
#   is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }
#   is_apple_silicon() { [[ "$(uname -m)" == "arm64" ]]; }

#   # Aliases for different naming conventions
#   info() { log_info "$@"; }
#   success() { log_success "$@"; }
#   warn() { log_warn "$@"; }
#   error() { log_error "$@"; }

#   # Define required XDG environment variables if we can't load utils.zsh
#   export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
#   export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
#   export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
#   export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
#   export ZDOTDIR_TARGET="$XDG_CONFIG_HOME/zsh"
#   export ZDOTDIR_SRC="$DOTFILES/config/zsh"
#   export BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
# fi
# ========================================================================
# Main Installation Function
# ========================================================================
function main() {
  log_info "Starting dotfiles setup for macOS..."

  # Ensure utils.zsh is available for core functions
  if [[ ! -f "$UTILS_PATH" ]]; then
    error "utils.zsh not found at $UTILS_PATH"
    error "This file is required for installation"
    error "Please ensure the dotfiles repository is correctly cloned"
    exit 1
  fi

  # Re-source utils.zsh to ensure all functions are available
  source "$UTILS_PATH"

  # Check system requirements
  check_requirements

  # Verify repository structure
  verify_repo_structure

  # Show install plan
  info "Installation plan:"
  echo "  ✓ Set up ZSH configuration"
  echo "  ✓ Configure CLI tools"
  [[ "$NO_MACOS" == "false" ]] && echo "  ✓ Configure macOS preferences"

  # Start installation timer
  local start_time=$(date +%s)

  # Create XDG directories
  ensure_dir "$XDG_CONFIG_HOME"
  ensure_dir "$XDG_CACHE_HOME"
  ensure_dir "$XDG_DATA_HOME"
  ensure_dir "$XDG_STATE_HOME"

  # # Create Atuin directories
  # ensure_dir "$XDG_DATA_HOME/atuin"
  # ensure_dir "$XDG_CONFIG_HOME/atuin"

  # Setup components using refactored functions
  setup_zsh

  if [[ "$NO_BREW" == "false" ]]; then
    setup_homebrew
  else
    info "Skipping Homebrew setup (--no-brew flag used)"
  fi

  # Install essential tools and create symlinks
  install_essential_tools
  setup_cli_tools
  setup_macos_preferences

  # Calculate time taken
  local end_time=$(date +%s)
  local time_taken=$((end_time - start_time))
  local minutes=$((time_taken / 60))
  local seconds=$((time_taken % 60))

  success "Dotfiles setup complete! 🎉"
  info "Time taken: ${minutes}m ${seconds}s"

  if [[ -d "$BACKUP_DIR" && "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
    local backup_size=$(du -sh "$BACKUP_DIR" | cut -f1)
    info "Backup created at $BACKUP_DIR ($backup_size)"
  fi

  info "Please log out and log back in, or restart your computer for all changes to take effect."
  info "To finish setting up your shell, run: exec zsh"
}

# ========================================================================
# Parse command-line arguments
# ========================================================================
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --no-macos)
      NO_MACOS=true
      shift
      ;;
    --minimal)
      MINIMAL=true
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --no-brew     Skip Homebrew installation and updates"
      echo "  --no-macos    Skip macOS preferences configuration"
      echo "  --minimal     Install only essential configurations"
      echo "  --help        Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      shift
      ;;
    esac
  done
}

# Initialize optional flags
NO_MACOS=false
MINIMAL=false

# Run the script
parse_args "$@"
main "$@"




###################
# #!/usr/bin/env zsh
#
# # ========================================================================
# # bootstrap.zsh - macOS dotfiles bootstrap script
# # ========================================================================
#
# set -euo pipefail
#
# # ========================================================================
# # Environment Configuration
# # ========================================================================
# export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
# export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
# export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
# export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
# export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
#
# # Source utilities
# # source "$DOTFILES/utils.zsh"
#
# # ========================================================================
# # System Requirements Check
# # ========================================================================
# check_requirements() {
#     info "Checking system requirements..."
#
#     # Check if running on macOS
#     if ! is_macos; then
#         error "This script is designed for macOS only."
#         exit 1
#     fi
#
#     # Check if running on Apple Silicon
#     if ! is_apple_silicon; then
#         error "This script is designed for Apple Silicon Macs only."
#         exit 1
#     fi
#
#     # Check for required commands
#     local required_commands=(
#         "git"
#         "curl"
#         "zsh"
#     )
#
#     for cmd in "${required_commands[@]}"; do
#         if ! has_command "$cmd"; then
#             error "Required command not found: $cmd"
#             exit 1
#         fi
#     done
#
#     success "System requirements met"
# }
#
# # ========================================================================
# # Dotfiles Setup
# # ========================================================================
# setup_dotfiles() {
#     info "Setting up dotfiles..."
#
#     # Clone dotfiles repository if it doesn't exist
#     if [[ ! -d "$DOTFILES" ]]; then
#         info "Cloning dotfiles repository..."
#         git clone https://github.com/yourusername/dotfiles.git "$DOTFILES"
#     fi
#
#     # Update dotfiles
#     info "Updating dotfiles..."
#     cd "$DOTFILES"
#     git pull origin main
#
#     # Run installation script
#     info "Running installation script..."
#     ./install.zsh
#
#     success "Dotfiles setup complete"
# }
#
# # ========================================================================
# # Main Function
# # ========================================================================
# main() {
#     info "Starting dotfiles bootstrap for macOS..."
#
#     # Check system requirements
#     check_requirements
#
#     # Setup dotfiles
#     setup_dotfiles
#
#     success "Bootstrap complete! 🎉"
#     info "Please log out and log back in, or restart your computer for all changes to take effect."
#     info "To finish setting up your shell, run: exec zsh"
# }
#
# # Run the script
# main "$@"
#
#
#
# #!/usr/bin/env bash
# # macOS Dotfiles Bootstrap Script
# # Sets up a complete macOS environment with dotfiles, apps, and preferences
#
# set -euo pipefail
#
# # -----------------------------------------------------------------------------
# # Environment Configuration
# # -----------------------------------------------------------------------------
# export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
# export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
# export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
# export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
# export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
# export ZDOTDIR="${ZDOTDIR:-$DOTFILES/config/zsh}"
#
# # -----------------------------------------------------------------------------
# # Utility Functions
# # -----------------------------------------------------------------------------
# log() { printf "%b\n" "$*" >&2; }
# info() { log "\033[34m[INFO]\033[0m $*"; }
# warn() { log "\033[33m[WARN]\033[0m $*"; }
# error() { log "\033[31m[ERROR]\033[0m $*"; }
# success() { log "\033[32m[OK]\033[0m $*"; }
#
# # System detection
# is_macos() { [[ "$OSTYPE" == darwin* ]]; }
# is_apple_silicon() { [[ "$(uname -m)" == "arm64" ]]; }
# has_command() { command -v "$1" >/dev/null 2>&1; }
#
# # File operations
# backup_file() {
#   local file="$1"
#   local backup="${file}.backup-$(date +%Y%m%d_%H%M%S)"
#
#   if [[ -e "$file" ]]; then
#     info "Backing up $file to $backup"
#     mv "$file" "$backup"
#   fi
# }
#
# make_link() {
#   local src_orig="$1"
#   local dst_symlink="$2"
#
#   if [[ ! -e "$src_orig" ]]; then
#     error "Source does not exist: $src_orig"
#     return 1
#   fi
#
#   # Create parent directory if it doesn't exist
#   local dst_dir=$(dirname "$dst_symlink")
#   if [[ ! -d "$dst_dir" ]]; then
#     info "Creating directory: $dst_dir"
#     mkdir -p "$dst_dir"
#   fi
#
#   # Backup existing files
#   if [[ -e "$dst_symlink" && ! -L "$dst_symlink" ]]; then
#     backup_file "$dst_symlink"
#   fi
#
#   info "Linking $src_orig → $dst_symlink"
#   ln -sf "$src_orig" "$dst_symlink"
# }
#
# ensure_dir() {
#   local dir="$1"
#   if [[ ! -d "$dir" ]]; then
#     info "Creating directory: $dir"
#     mkdir -p "$dir"
#   fi
# }
#
# # -----------------------------------------------------------------------------
# # Homebrew Setup
# # -----------------------------------------------------------------------------
# setup_homebrew() {
#   info "Setting up Homebrew..."
#
#   if ! has_command brew; then
#     info "Installing Homebrew..."
#     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#
#     if is_apple_silicon; then
#       eval "$(/opt/homebrew/bin/brew shellenv)"
#     else
#       eval "$(/usr/local/bin/brew shellenv)"
#     fi
#   else
#     info "Homebrew is already installed"
#   fi
#
#   # Update Homebrew
#   info "Updating Homebrew..."
#   brew update
#
#   # Install from Brewfile
#   if [[ -f "$DOTFILES/Brewfile" ]]; then
#     info "Installing packages from Brewfile..."
#     brew bundle install --file="$DOTFILES/Brewfile" --no-lock
#   else
#     warn "Brewfile not found at $DOTFILES/Brewfile"
#   fi
# }
#
# # -----------------------------------------------------------------------------
# # ZSH Setup
# # -----------------------------------------------------------------------------
# setup_zsh() {
#   info "Setting up ZSH configuration..."
#   ensure_dir "$ZDOTDIR"
#
#   # Setup .zshenv in home directory
#   local zshenv="$HOME/.zshenv"
#   info "Setting up .zshenv at $zshenv"
#
#   cat >"$zshenv" <<EOF
# # Minimal stub for Zsh
# export ZDOTDIR="$ZDOTDIR"
# [[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
# EOF
#   success "Created $zshenv pointing to $ZDOTDIR"
#
#   # Make sure ZSH config files are linked
#   if [[ -d "$DOTFILES/config/zsh" ]]; then
#     make_link "$DOTFILES/config/zsh/.zshrc" "$ZDOTDIR/.zshrc"
#     make_link "$DOTFILES/config/zsh/.zprofile" "$ZDOTDIR/.zprofile"
#     make_link "$DOTFILES/config/zsh/.zshenv" "$ZDOTDIR/.zshenv"
#     make_link "$DOTFILES/config/zsh/aliases.zsh" "$ZDOTDIR/aliases.zsh"
#     make_link "$DOTFILES/config/zsh/functions.zsh" "$ZDOTDIR/functions.zsh"
#     make_link "$DOTFILES/config/zsh/fzf.zsh" "$ZDOTDIR/fzf.zsh"
#   else
#     error "ZSH config directory not found at $DOTFILES/config/zsh"
#   fi
# }
#
# # -----------------------------------------------------------------------------
# # CLI Tools Configuration
# # -----------------------------------------------------------------------------
# setup_tools() {
#   info "Setting up CLI tools configuration..."
#
#   # Ghostty terminal
#   if [[ -f "$DOTFILES/config/ghostty/config" ]]; then
#     ensure_dir "$XDG_CONFIG_HOME/ghostty"
#     make_link "$DOTFILES/config/ghostty/config" "$XDG_CONFIG_HOME/ghostty/config"
#   fi
#
#   # Neovim
#   if [[ -d "$DOTFILES/config/nvim" ]]; then
#     ensure_dir "$XDG_CONFIG_HOME/nvim"
#     make_link "$DOTFILES/config/nvim/init.lua" "$XDG_CONFIG_HOME/nvim/init.lua"
#
#     # Link Neovim config files recursively
#     if has_command find; then
#       find "$DOTFILES/config/nvim/lua" -type f -name "*.lua" | while read -r file; do
#         relative_path="${file#$DOTFILES/config/nvim/}"
#         target_dir="$(dirname "$XDG_CONFIG_HOME/nvim/$relative_path")"
#         ensure_dir "$target_dir"
#         make_link "$file" "$XDG_CONFIG_HOME/nvim/$relative_path"
#       done
#     fi
#   fi
#
#   # Starship prompt
#   make_link "$DOTFILES/config/starship.toml" "$XDG_CONFIG_HOME/starship.toml"
#
#   # Atuin shell history
#   ensure_dir "$XDG_CONFIG_HOME/atuin"
#   make_link "$DOTFILES/config/atuin/config.toml" "$XDG_CONFIG_HOME/atuin/config.toml"
#
#   # Bat (cat replacement)
#   ensure_dir "$XDG_CONFIG_HOME/bat"
#   make_link "$DOTFILES/config/bat/config" "$XDG_CONFIG_HOME/bat/config"
#
#   # Zellij terminal multiplexer
#   ensure_dir "$XDG_CONFIG_HOME/zellij"
#   make_link "$DOTFILES/config/zellij/config.yml" "$XDG_CONFIG_HOME/zellij/config.yml"
#
#   # Espanso text expander
#   if [[ -f "$DOTFILES/config/espanso/match/base.yml" ]]; then
#     ensure_dir "$XDG_CONFIG_HOME/espanso/match"
#     ensure_dir "$XDG_CONFIG_HOME/espanso/config"
#     make_link "$DOTFILES/config/espanso/match/base.yml" "$XDG_CONFIG_HOME/espanso/match/base.yml"
#     make_link "$DOTFILES/config/espanso/config/default.yml" "$XDG_CONFIG_HOME/espanso/config/default.yml"
#   fi
#
#   info "Setting up GUI applications configuration..."
#
#   # Karabiner (keyboard customization)
#   ensure_dir "$XDG_CONFIG_HOME/karabiner"
#   make_link "$DOTFILES/config/karabiner/karabiner.json" "$XDG_CONFIG_HOME/karabiner/karabiner.json"
#
#   # VS Code
#   ensure_dir "$HOME/Library/Application Support/Code/User"
#   make_link "$DOTFILES/config/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
#   make_link "$DOTFILES/config/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
#
#   # Cursor (VS Code-based editor)
#   ensure_dir "$HOME/Library/Application Support/Cursor/User"
#   make_link "$DOTFILES/config/cursor/settings.json" "$HOME/Library/Application Support/Cursor/User/settings.json"
#   make_link "$DOTFILES/config/cursor/keybindings.json" "$HOME/Library/Application Support/Cursor/User/keybindings.json"
#
#   # Hammerspoon
#   ensure_dir "$HOME/.hammerspoon"
#   make_link "$DOTFILES/config/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"
#
#   # Claude Desktop
#   ensure_dir "$HOME/Library/Application Support/Claude"
#   make_link "$DOTFILES/config/ai/claude/claude_desktop_config.json" "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
# }
#
# # -----------------------------------------------------------------------------
# # Development Environment Setup
# # -----------------------------------------------------------------------------
# setup_dev_environment() {
#   info "Setting up development environment..."
#
#   # Ensure development directories exist
#   ensure_dir "$HOME/src"
#   ensure_dir "$HOME/go/bin"
#
#   # Setup git config if not already configured
#   if [[ ! -f "$HOME/.gitconfig" ]]; then
#     info "Setting up initial Git configuration..."
#
#     local git_name git_email
#     read -p "Enter your Git name: " git_name
#     read -p "Enter your Git email: " git_email
#
#     git config --global user.name "$git_name"
#     git config --global user.email "$git_email"
#     git config --global init.defaultBranch main
#     git config --global core.editor "$(which nvim || which vim)"
#     git config --global pull.rebase true
#
#     success "Git configured"
#   fi
#
#   # Install or update developer tools
#   if has_command pyenv; then
#     info "Setting up Python environment with pyenv..."
#     pyenv install --skip-existing 3.11
#     pyenv global 3.11
#   fi
#
#   if has_command fnm; then
#     info "Setting up Node.js environment with fnm..."
#     fnm install --lts
#     fnm default lts-latest
#   fi
# }
#
# # -----------------------------------------------------------------------------
# # Main Setup Function
# # -----------------------------------------------------------------------------
# main() {
#   info "Starting dotfiles setup for macOS..."
#
#   # Check if running on macOS
#   if ! is_macos; then
#     error "This script is designed for macOS only."
#     exit 1
#   fi
#
#   # Create XDG directories
#   ensure_dir "$XDG_CONFIG_HOME"
#   ensure_dir "$XDG_CACHE_HOME"
#   ensure_dir "$XDG_DATA_HOME"
#   ensure_dir "$XDG_STATE_HOME"
#
#   # Setup components
#   setup_zsh
#   setup_homebrew
#   setup_tools
#   setup_macos_preferences
#   # setup_dev_environment
#
#   success "Dotfiles setup complete! 🎉"
#   info "Please log out and log back in, or restart your computer for all changes to take effect."
#   info "To finish setting up your shell, run: exec zsh"
# }
#
# # Run main function if script is executed directly
# if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
#   main "$@"
# fi
#
# # ###############
# #
# # # Create XDG directories
# # ensure_dir "$XDG_CONFIG_HOME"
# # ensure_dir "$XDG_CACHE_HOME"
# # ensure_dir "$XDG_DATA_HOME"
# #
# # # Setup minimal .zshenv
# # setup_zshenv() {
# #   local zshenv="$HOME/.zshenv"
# #   info "Setting up .zshenv at $zshenv"
# #
# #   cat >"$zshenv" <<EOF
# # # Minimal stub for Zsh
# # export ZDOTDIR="$ZDOTDIR"
# # [[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
# # EOF
# #
# #   success "Created $zshenv pointing to $ZDOTDIR"
# # }
# #
# # function setup_cli() {
# #   # Setup ZSH
# #
# #   make_link "$DOTFILES/config/starship.toml" "$XDG_CONFIG_HOME/starship.toml"
# #
# #   ensure_dir "$XDG_CONFIG_HOME/atuin"
# #   make_link "$DOTFILES/config/atuin/config.toml" "$XDG_CONFIG_HOME/atuin"
# #
# #   ensure_dir "$XDG_CONFIG_HOME/bat"
# #   make_link "$DOTFILES/config/bat/config" "$XDG_CONFIG_HOME/bat/config"
# #
# #   ensure_dir "$XDG_CONFIG_HOME/zellij"
# #   make_link "$DOTFILES/config/zellij/config.yml" "$XDG_CONFIG_HOME/zellij/config.yml"
# #
# #   ensure_dir "$XDG_CONFIG_HOME/karabiner"
# #   make_link "$DOTFILES/config/karabiner/karabiner.json" "$XDG_CONFIG_HOME/karabiner/karabiner.json"
# #
# #   make_link "$DOTFILES/config/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
# #   make_link "$DOTFILES/config/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
# #
# #   make_link "$DOTFILES/config/cursor/settings.json" "$HOME/Library/Application Support/Cursor/User/settings.json"
# #   make_link "$DOTFILES/config/cursor/keybindings.json" "$HOME/Library/Application Support/Cursor/User/keybindings.json"
# #
# #   ensure_dir "$HOME/.hammerspoon"
# #   make_link "$DOTFILES/config/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"
# #
# #   # ensure_dir "$HOME/.hammerspoon"
# #   make_link "$DOTFILES/config/ai/claude/claude_desktop_config.json" "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
# #
# # }
# #
# #
# #
# #
# #
# # main() {
# #   info "Starting minimal ZSH bootstrap..."
# #
# #   setup_zshenv
# #
# # # Install Homebrew and packages
# # # ensure_homebrew
# # # brew_bundle "$@"
# #
# #   success "Bootstrap complete! Please restart your shell or run 'exec zsh'"
# # }
# #
# # setup_zshenv
# #
# # main "$@"
# #
# #
# # ##################
# # #
# # # setup_zshenv
# # # make_link "$DOTFILES/config/zsh" "$ZDOTDIR"
# # #
# # # function setup_brew() {
# # # }
# # #
# # # function setup_shell() {
# # #   make_link "$DOTFILES/config/starship.toml" "$XDG_CONFIG_HOME/starship.toml"
# # #   make_link "$DOTFILES/config/atuin" "$XDG_CONFIG_HOME/atuin"
# # #   make_link "$DOTFILES/config/bat/config" "$XDG_CONFIG_HOME/bat/config"
# # #   make_link "$DOTFILES/config/zellij/config.yml" "$XDG_CONFIG_HOME/zellij/config.yml"
# # # }
# # #
# # # DOTFILES_CONFIG="$DOTFILES/config"
# # #
# # # DOTFILES_ZSH
# # #
# # # declare -A DOTFILE_TO_SYMLINK_MAP=(
# # #   ["zsh/.zshrc"]=".zshrc"
# # #   ["zsh/.zprofile"]=".zprofile"
# # #   ["zsh/aliases.zsh"]="$ZDOTDIR/aliases.zsh"
# # #   ["zsh/functions.zsh"]="$ZDOTDIR/functions.zsh"
# # #   ["zsh/fzf.zsh"]="$ZDOTDIR/fzf.zsh"
# # #
# # #   ["$DOTFILES/nvim"]="$ZDOTDIR/nvim"
# # #   ["$DOTFILES/nvim"]="$ZDOTDIR/nvim"
# # # )
# # #
# # # info "Starting dotfiles installation..."
# #
# # #########################
# #
# # # info "Starting dotfiles installation..."
# #
# # # make_link "$DOTFILES/config/zsh/.zshrc" "$ZDOTDIR/.zshrc"
# # # make_link "$DOTFILES/config/zsh/.zprofile" "$ZDOTDIR/.zprofile"
# # # make_link "$DOTFILES/config/zsh/aliases.zsh" "$ZDOTDIR/aliases.zsh"
# # # make_link "$DOTFILES/config/zsh/functions.zsh" "$ZDOTDIR/functions.zsh"
# # # make_link "$DOTFILES/config/zsh/fzf.zsh" "$ZDOTDIR/fzf.zsh"
# #
# # # make_link "$DOTFILES/Brewfile" "$HOME/.Brewfile"
# #
# # # ensure_dir "$XDG_CONFIG_HOME/ghostty"
# # # make_link "$DOTFILES/config/ghostty/config" "$XDG_CONFIG_HOME/ghostty/config"
# #
# # # Development tools
# # # ensure_dir "$XDG_CONFIG_HOME/nvim"
# # # make_link "$DOTFILES/config/nvim/init.lua" "$XDG_CONFIG_HOME/nvim/init.lua"
# # # make_link "$DOTFILES/config/nvim/lazyvim.json" "$XDG_CONFIG_HOME/nvim/lazyvim.json"
# # # make_link "$DOTFILES/config/nvim/lazy-lock.json" "$XDG_CONFIG_HOME/nvim/lazy-lock.json"
# # # make_link "$DOTFILES/config/nvim/README.md" "$XDG_CONFIG_HOME/nvim/README.md"
# # # make_link "$DOTFILES/config/nvim/lua/lazy-lock.json" "$XDG_CONFIG_HOME/nvim/lazy-lock.json"
# #
# # # Recursively link all lua files while preserving directory structure
# # # find "$DOTFILES/config/nvim/lua" -type f -name "*.lua" | while read -r file; do
# # #   relative_path="${file#$DOTFILES/config/nvim/}"
# # #   target_dir="$(dirname "$XDG_CONFIG_HOME/nvim/$relative_path")"
# # #   ensure_dir "$target_dir"
# # #   make_link "$file" "$XDG_CONFIG_HOME/nvim/$relative_path"
# # # done
# #
# # # make_link "$DOTFILES/config/starship.toml" "$XDG_CONFIG_HOME/starship.toml"
# # # make_link "$DOTFILES/config/atuin" "$XDG_CONFIG_HOME/atuin"
# # # make_link "$DOTFILES/config/bat/config" "$XDG_CONFIG_HOME/bat/config"
# # # make_link "$DOTFILES/config/zellij/config.yml" "$XDG_CONFIG_HOME/zellij/config.yml"
# #
# # # ensure_dir "$XDG_CONFIG_HOME/espanso"
# # # ensure_dir "$XDG_CONFIG_HOME/espanso/match"
# # # ensure_dir "$XDG_CONFIG_HOME/espanso/config"
# # # make_link "$DOTFILES/config/espanso/match/base.yml" "$XDG_CONFIG_HOME/espanso/match/base.yml"
# # # make_link "$DOTFILES/config/espanso/config/default.yml" "$XDG_CONFIG_HOME/espanso/config/default.yml"
# #
