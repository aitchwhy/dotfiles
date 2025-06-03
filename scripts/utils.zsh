#!/usr/bin/env zsh
# ========================================================================
# ZSH Utils - Common utilities for shell scripts and configurations
# ========================================================================
# This file contains utility functions that are shared across multiple
# shell scripts and configuration files. All functions are exported for
# sourcing and use in various zsh scripts.
#
# USAGE: Source this file in your .zprofile or other zsh configuration
# files to make these utilities available to your shell.
# Recommended: source "${ZDOTDIR:-$HOME/dotfiles/config/zsh}/utils.zsh"

# ========================================================================
# Internal Variables - Not Exported
# ========================================================================
# These variables are used within this file but NOT exported globally
# The environment variables should be set in .zshenv for consistent
# cross-shell access

# ========================================================================
# ANSI Color Codes - For Internal Use
# ========================================================================
# These color codes are used within the logging functions
typeset -g RESET="\033[0m"
typeset -g BLACK="\033[0;30m"
typeset -g RED="\033[0;31m"
typeset -g GREEN="\033[0;32m"
typeset -g YELLOW="\033[0;33m"
typeset -g BLUE="\033[0;34m"
typeset -g MAGENTA="\033[0;35m"
typeset -g CYAN="\033[0;36m"
typeset -g WHITE="\033[0;37m"

###########################################################################
# # TODO: zsh util functions
###########################################################################
# ❯ tldr --platform osx zsh
#   zsh
#   Z SHell, a Bash-compatible command-line interpreter.
#   See also: bash, histexpand.
#   More information: https://www.zsh.org.
#   Start an interactive shell session:
#     zsh
#   Execute specific [c]ommands:
#     zsh -c "echo Hello world"
#   Execute a specific script:
#     zsh path/to/script.zsh
#   Check a specific script for syntax errors without executing it:
#     zsh --no-exec path/to/script.zsh
#   Execute specific commands from stdin:
#     echo Hello world | zsh
#   Execute a specific script, printing each command in the script before executing it:
#     zsh --xtrace path/to/script.zsh
#   Start an interactive shell session in verbose mode, printing each command before executing it:
#     zsh --verbose
#   Execute a specific command inside zsh with disabled glob patterns:
#     noglob command
###########################################################################

# ========================================================================
# Logging Functions
# ========================================================================

# Log information message
function log_info() {
  printf "${BLUE}[INFO]${RESET} %s\n" "$*"
}

# Log success message
function log_success() {
  printf "${GREEN}[SUCCESS]${RESET} %s\n" "$*"
}

# Log warning message
function log_warn() {
  printf "${YELLOW}[WARNING]${RESET} %s\n" "$*" >&2
}

# Log error message
function log_error() {
  printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2
}
 
# Aliases for different naming conventions
function info() { log_info "$@"; }
function success() { log_success "$@"; }
function warn() { log_warn "$@"; }
function error() { log_error "$@"; }

# # List all utility functions exported by this file
# function list_utils() {
#   local util_funcs=$(functions | grep "^[a-z].*() {" | grep -v "^_" | sort)
#   local count=$(echo "$util_funcs" | wc -l | tr -d ' ')
#
#   log_info "Available utility functions ($count total):"
#   echo "$util_funcs" | sed 's/() {.*//' | column
# }

# ========================================================================
# Shell Detection and Environment
# ========================================================================

# Detect if running interactively
# export function is_interactive() {
#   [[ -o interactive ]]
# }

# Detect if being sourced
function is_sourced() {
  [[ "${FUNCNAME[1]-main}" != main ]]
}

# ========================================================================
# Command and System Detection
# ========================================================================

# Check if a command exists
function has_command() {
  command -v "$1" &>/dev/null
}

# System detection functions
export function is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

export function is_linux() {
  [[ "$(uname -s)" == "Linux" ]]
}

export function is_apple_silicon() {
  [[ "$(uname -m)" == "arm64" ]] && is_macos
}

export function is_rosetta() {
  # Check if a process is running under Rosetta translation
  if is_apple_silicon; then
    local arch_output
    arch_output=$(arch)
    [[ "$arch_output" != "arm64" ]]
  else
    false
  fi
}

export function get_macos_version() {
  if is_macos; then
    sw_vers -productVersion
  else
    echo "Not macOS"
  fi
}


# ========================================================================
# File & Directory Operations
# ========================================================================

# Create a directory if it doesn't exist
export function ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    log_success "Created directory: $dir"
  fi
}

# ========================================================================
# Homebrew Installation Functions
# ========================================================================

# install brew if not exists
export function install_brew() {
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

# uninstall brew
export function uninstall_brew() {
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
}



# ========================================================================
# Path Management Functions
# ========================================================================

# Add a directory to PATH if it exists and isn't already in PATH
export function path_add() {
  local dir="$1"
  if [[ -d "$dir" ]] && [[ ":$PATH:" != *":$dir:"* ]]; then
    export PATH="$dir:$PATH"
    return 0
  fi
  return 1
}

# Remove a directory from PATH
export function path_remove() {
  local dir="$1"
  if [[ ":$PATH:" == *":$dir:"* ]]; then
    export PATH=${PATH//:$dir:/:}  # Remove middle
    export PATH=${PATH/#$dir:/}    # Remove beginning
    export PATH=${PATH/%:$dir/}    # Remove end
    return 0
  fi
  return 1
}

# ========================================================================
# macOS System Preferences
# ========================================================================

# Apply common macOS system preferences
export function defaults_apply() {
  if ! is_macos; then
    log_error "Not running on macOS"
    return 1
  fi

  log_info "Applying macOS preferences..."

  # Keyboard settings
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  defaults write NSGlobalDomain KeyRepeat -int 2

  # File system behavior
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

  # Dock settings
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock show-recents -bool false

  # Trackpad settings
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
    killall "$app" >/dev/null 2>&1 || true
  done

  log_success "macOS preferences applied"
}

# ========================================================================
# Core Installation Functions
# ========================================================================


# Setup Homebrew and install packages
export function init_brew() {
  info "Setting up Homebrew..."
  has_command brew || install_brew
  brew bundle install --verbose --file="$DOTFILES/Brewfile.core" --all --force
}

# Setup ZSH configuration
export function init_zsh() {
  info "Setting up ZSH configuration..."

  # Use environment vars if set, fall back to internal vars if not
  local zdotdir_src="${ZDOTDIR:-$DOTFILES/config/zsh}"

  # Create .zshenv in home directory pointing to dotfiles
  info "Creating .zshenv to point to dotfiles ZSH configuration"
  cat >"$HOME/.zshenv" <<EOF
# ZSH configuration bootstrapper
# Auto-generated by dotfiles setup
export ZDOTDIR="$zdotdir_src"
[[ -f "$zdotdir_src/.zshenv" ]] && source "$zdotdir_src/.zshenv"
EOF

  chmod 644 "$HOME/.zshenv"
  log_success "Created $HOME/.zshenv pointing to $zdotdir_src"
}
