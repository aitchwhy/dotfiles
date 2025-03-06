#!/usr/bin/env zsh
# ========================================================================
# install.zsh - macOS dotfiles installation script
# ========================================================================

set -euo pipefail

# ========================================================================
# Source or Define Utility Functions
# ========================================================================

# Determine DOTFILES path
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
export UTILS_PATH="$DOTFILES/config/zsh/utils.zsh"

# Source utils.zsh if available, or define minimal required functions
if [[ -f "$UTILS_PATH" ]]; then
  source "$UTILS_PATH"
else
  # Define minimal required utility functions for bootstrapping
  has_command() { command -v "$1" >/dev/null 2>&1; }

  # Colored output
  log_info() { printf '\033[0;34m[INFO]\033[0m %s\n' "$*"; }
  log_success() { printf '\033[0;32m[SUCCESS]\033[0m %s\n' "$*"; }
  log_warn() { printf '\033[0;33m[WARNING]\033[0m %s\n' "$*" >&2; }
  log_error() { printf '\033[0;31m[ERROR]\033[0m %s\n' "$*" >&2; }

  # Directory operations
  ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
      mkdir -p "$dir"
      log_success "Created directory: $dir"
    fi
  }

  # System detection
  is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }
  is_apple_silicon() { [[ "$(uname -m)" == "arm64" ]]; }

  # Aliases for different naming conventions
  info() { log_info "$@"; }
  success() { log_success "$@"; }
  warn() { log_warn "$@"; }
  error() { log_error "$@"; }
fi

# ========================================================================
# Environment Configuration
# ========================================================================
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export ZDOTDIR_TARGET="$XDG_CONFIG_HOME/zsh"
export ZDOTDIR_SRC="$DOTFILES/config/zsh"
export BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Source dotfiles symlink map
if [[ -f "$DOTFILES/config/zsh/system.zsh" ]]; then
  source "$DOTFILES/config/zsh/system.zsh"
fi

# ========================================================================
# System Requirements Check
# ========================================================================
check_requirements() {
  info "Checking system requirements..."

  # Check if running on macOS
  if ! is_macos; then
    error "This script is designed for macOS only."
    exit 1
  fi

  # Check if running on Apple Silicon
  if ! is_apple_silicon; then
    error "This script is designed for Apple Silicon Macs only."
    exit 1
  fi

  # Check for required commands
  local required_commands=(
    "git"
    "curl"
    "zsh"
  )

  for cmd in "${required_commands[@]}"; do
    if ! has_command "$cmd"; then
      error "Required command not found: $cmd"
      exit 1
    fi
  done

  success "System requirements met"
}

# ========================================================================
# Repository Verification
# ========================================================================
verify_repo_structure() {
  info "Verifying dotfiles repository structure..."

  # Check if dotfiles directory exists
  if [[ ! -d "$DOTFILES" ]]; then
    error "Dotfiles directory not found at $DOTFILES"
    error "Please clone the repository first: git clone <repo-url> $DOTFILES"
    exit 1
  fi

  # Check if it's a git repository
  if [[ ! -d "$DOTFILES/.git" ]]; then
    error "The dotfiles directory is not a git repository"
    error "Please clone the repository properly: git clone <repo-url> $DOTFILES"
    exit 1
  fi

  # Check for critical directories and files
  local missing_items=()

  [[ ! -f "$DOTFILES/Brewfile" ]] && missing_items+=("Brewfile")
  [[ ! -d "$DOTFILES/config" ]] && missing_items+=("config dir")
  [[ ! -d "$DOTFILES/config/zsh" ]] && missing_items+=("config/zsh dir")
  [[ ! -f "$DOTFILES/config/zsh/.zshrc" ]] && missing_items+=("config/zsh/.zshrc file")
  [[ ! -f "$DOTFILES/config/zsh/.zprofile" ]] && missing_items+=("config/zsh/.zprofile file")
  [[ ! -d "$DOTFILES/config/nvim" ]] && missing_items+=("config/nvim dir")

  if ((${#missing_items[@]} > 0)); then
    error "The dotfiles repository is missing critical components:"
    for item in "${missing_items[@]}"; do
      error "  - Missing $item"
    done
    error "Please ensure you've cloned the correct repository."
    exit 1
  fi

  success "Repository structure verified successfully"
}

# ========================================================================
# ZSH Setup
# ========================================================================
setup_zsh() {
  info "Setting up ZSH configuration..."

  # # Backup existing .zshenv if it exists
  # if [[ -f "$HOME/.zshenv" ]]; then
  #   rm -f "$HOME/.zshenv"
  # fi

  # Create .zshenv in home directory pointing to dotfiles
  info "Creating .zshenv to point to dotfiles ZSH configuration"
  cat >"$HOME/.zshenv" <<EOF
# ZSH configuration bootstrapper
# Auto-generated by dotfiles installation script
export ZDOTDIR="$ZDOTDIR_SRC"
[[ -f "$ZDOTDIR_SRC/.zshenv" ]] && source "$ZDOTDIR_SRC/.zshenv"
EOF
  #   cat >"$HOME/.zshenv" <<EOF
  # # ZSH configuration bootstrapper
  # # Auto-generated by dotfiles installation script
  # export ZDOTDIR="$ZDOTDIR_TARGET"
  # [[ -f "$ZDOTDIR_TARGET/.zshenv" ]] && source "$ZDOTDIR_TARGET/.zshenv"
  # EOF

  chmod 644 "$HOME/.zshenv"
  success "Created $HOME/.zshenv pointing to $ZDOTDIR_SRC"

  # # Create symlink from XDG_CONFIG_HOME/zsh to dotfiles config/zsh
  # if [[ ! -L "$ZDOTDIR_TARGET" ]]; then
  #   rm -rf "$ZDOTDIR_TARGET"
  #   ln -sf "$DOTFILES/config/zsh" "$ZDOTDIR_TARGET"
  #   success "Linked ZSH configuration to $ZDOTDIR_TARGET"
  # fi
}

# ========================================================================
# Homebrew Setup
# ========================================================================
setup_homebrew() {
  info "Setting up Homebrew..."

  # info "Brew cleanup (scrub)..."
  # brew cleanup --scrub

  if [[ ! -x /opt/homebrew/bin/brew ]]; then
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
    brew bundle install --verbose --global --all --force
  else
    warn "Brewfile not found at $DOTFILES/Brewfile"
  fi
}

# ========================================================================
# macOS System Preferences
# ========================================================================
setup_macos_preferences() {
  info "Configuring macOS system preferences..."

  # Faster key repeat
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 15

  # Disable press-and-hold for keys in favor of key repeat
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

  # Always show file extensions
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true

  # Don't write .DS_Store files on network drives
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

  # Dock settings
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock show-recents -bool false

  # Enable trackpad tap to click
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

  # Finder settings
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder _FXSortFoldersFirst -bool true

  # Restart affected applications
  for app in "Finder" "Dock"; do
    killall "$app" &>/dev/null || true
  done

  success "macOS preferences configured"
}

# ========================================================================
# Main Installation Function
# ========================================================================
main() {
  info "Starting dotfiles setup for macOS..."

  # Check system requirements
  check_requirements

  # Verify repository structure
  verify_repo_structure

  # Show install plan
  info "Installation plan:"
  echo "  ✓ Set up ZSH configuration"
  [[ "$NO_BREW" == "false" ]] && echo "  ✓ Set up Homebrew packages"
  echo "  ✓ Configure CLI tools"
  [[ "$NO_MACOS" == "false" ]] && echo "  ✓ Configure macOS preferences"

  # Start installation timer
  local start_time=$(date +%s)

  # Create XDG directories
  ensure_dir "$XDG_CONFIG_HOME"
  ensure_dir "$XDG_CACHE_HOME"
  ensure_dir "$XDG_DATA_HOME"
  ensure_dir "$XDG_STATE_HOME"

  # Create Atuin directories
  ensure_dir "$XDG_DATA_HOME/atuin"
  ensure_dir "$XDG_CONFIG_HOME/atuin"

  # Setup components
  setup_zsh

  if [[ "$NO_BREW" == "false" ]]; then
    setup_homebrew
  else
    info "Skipping Homebrew setup (--no-brew flag used)"
  fi

  setup_cli_tools

  if [[ "$NO_MACOS" == "false" ]]; then
    setup_macos_preferences
  else
    info "Skipping macOS preferences (--no-macos flag used)"
  fi

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

# Parse command-line arguments
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --no-brew)
      NO_BREW=true
      shift
      ;;
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
NO_BREW=false
NO_MACOS=false
MINIMAL=false

# Run the script
parse_args "$@"
main "$@"
