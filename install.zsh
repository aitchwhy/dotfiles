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
