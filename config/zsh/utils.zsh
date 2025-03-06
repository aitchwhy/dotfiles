#!/usr/bin/env zsh
# ========================================================================
# ZSH Utils - Common utilities for shell scripts and configurations
# ========================================================================
# This file contains utility functions that are shared across multiple
# shell scripts and configuration files.

# ========================================================================
# Shell Detection and Environment
# ========================================================================

# Detect if running interactively
function is_interactive() {
  [[ -o interactive ]]
}

# Detect if being sourced
function is_sourced() {
  [[ "${FUNCNAME[1]-main}" != main ]]
}

# Get the directory of the current script
function get_script_dir() {
  local source="${BASH_SOURCE[0]:-${(%):-%x}}"
  dirname "$(readlink -f "$source")"
}

# ========================================================================
# Command and System Detection
# ========================================================================

# Check if a command exists
function has_command() {
  command -v "$1" &>/dev/null
}

# System detection functions
function is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

function is_linux() {
  [[ "$(uname -s)" == "Linux" ]]
}

function is_apple_silicon() {
  [[ "$(uname -m)" == "arm64" ]] && is_macos
}

function is_rosetta() {
  # Check if a process is running under Rosetta translation
  if is_apple_silicon; then
    local arch_output
    arch_output=$(arch)
    [[ "$arch_output" != "arm64" ]]
  else
    false
  fi
}

function get_macos_version() {
  if is_macos; then
    sw_vers -productVersion
  else
    echo "Not macOS"
  fi
}
# ========================================================================
# Logging Functions
# ========================================================================

# ANSI color codes
RESET="\033[0m"
BLACK="\033[0;30m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"

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

# ========================================================================
# File & Directory Operations
# ========================================================================

# Create a directory if it doesn't exist
function ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    log_success "Created directory: $dir"
  fi
}

# Create a backup of a file
function backup_file() {
  local file="$1"
  local backup_dir="${2:-$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)}"
  
  if [[ -e "$file" ]]; then
    ensure_dir "$backup_dir"
    cp -a "$file" "$backup_dir/"
    log_success "Backed up $file to $backup_dir"
  else
    log_warn "File $file does not exist, skipping backup"
  fi
}

# Check if a file exists and is readable
function file_exists() {
  [[ -r "$1" ]]
}

# Safe source - source a file if it exists
function safe_source() {
  local file="$1"
  if file_exists "$file"; then
    source "$file"
    return 0
  else
    return 1
  fi
}

# ========================================================================
# Path Management Functions
# ========================================================================

# Add a directory to PATH if it exists and isn't already in PATH
function path_add() {
  local dir="$1"
  if [[ -d "$dir" ]] && [[ ":$PATH:" != *":$dir:"* ]]; then
    export PATH="$dir:$PATH"
    return 0
  fi
  return 1
}

# Remove a directory from PATH
function path_remove() {
  local dir="$1"
  if [[ ":$PATH:" == *":$dir:"* ]]; then
    export PATH=${PATH//:$dir:/:}  # Remove middle
    export PATH=${PATH/#$dir:/}    # Remove beginning
    export PATH=${PATH/%:$dir/}    # Remove end
    return 0
  fi
  return 1
}

# List PATH entries
function path_list() {
  echo $PATH | tr ':' '\n' | nl
}

# Print the expanded PATH as a list
function path_print() {
  echo "PATH components:"
  path_list | awk '{printf "  %2d: %s\n", $1, $2}'
}


# ========================================================================
# System & macOS Utilities
# ========================================================================
function sys() {
  case "$1" in
  env | env-grep)
    echo "======== env vars =========="
    if [ -z "$2" ]; then
      printenv | sort | awk -F= '{ printf "%-30s %s\n", $1, $2 }'
    else
      printenv | sort | grep -i "$2" | awk -F= '{ printf "%-30s %s\n", $1, $2 }'
    fi
    echo "============================" # Search environment variables
    ;;

  hidden | toggle-hidden)
    local current
    current=$(defaults read com.apple.finder AppleShowAllFiles)
    defaults write com.apple.finder AppleShowAllFiles $((!current))
    killall Finder
    echo "Finder hidden files: $((!current))" # Toggle macOS hidden files
    ;;

  ql | quick-look)
    if [ -z "$2" ]; then
      echo "Usage: sys ql <file>"
      return 1
    fi
    qlmanage -p "${@:2}" &>/dev/null # Quick Look files from terminal
    ;;

  weather | wttr)
    local city="${2:-}"
    curl -s "wttr.in/$city?format=v2" # Get weather information
    ;;

  killport | kill-port)
    local port="$2"
    if [[ -z "$port" ]]; then
      echo "Please specify a port number"
      return 1
    fi

    local pid
    pid=$(lsof -i ":$port" | awk 'NR!=1 {print $2}')

    if [[ -z "$pid" ]]; then
      echo "No process found on port $port"
      return 1
    fi

    echo "Killing process(es) on port $port: $pid"
    echo "$pid" | xargs kill -9
    echo "Process(es) killed" # Kill process on specified port
    ;;

  ducks | top-files)
    local count="${2:-10}"
    du -sh * | sort -rh | head -"$count" # Show largest files in directory
    ;;

  man | batman)
    MANPAGER="sh -c 'col -bx | bat -l man -p'" man "${@:2}" # Improved man pages with bat
    ;;

  ports | listening)
    sudo lsof -iTCP -sTCP:LISTEN -n -P # Show all listening ports
    ;;

  space | disk)
    df -h # Check disk space usage
    ;;

  cpu)
    top -l 1 | grep -E "^CPU" # Show CPU usage
    ;;

  mem | memory)
    vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages\s+([^:]+)[^\d]+(\d+)/ and printf("%-16s % 16.2f MB\n", "$1:", $2 * $size / 1048576);' # Show memory usage
    ;;

  path)
    path_print # List PATH entries
    ;;

  ip | myip)
    echo "Public IP: $(curl -s https://ipinfo.io/ip)"
    echo "Local IP: $(ipconfig getifaddr en0)" # Show IP addresses
    ;;

  help | *)
    if [[ "$1" != "help" && ! -z "$1" ]]; then
      echo "Unknown command: $1"
    fi

    echo "Usage: sys [command]"
    echo ""
    echo "Commands:"
    echo "  env [pattern]      - Display environment variables, optionally filtered"
    echo "  hidden             - Toggle hidden files in Finder"
    echo "  ql <file>          - Quick Look a file"
    echo "  weather [city]     - Show weather information"
    echo "  killport <port>    - Kill process running on specified port"
    echo "  ducks [count]      - Show largest files in current directory"
    echo "  man <command>      - Show man pages with syntax highlighting"
    echo "  ports              - Show all listening ports"
    echo "  space              - Check disk space usage"
    echo "  cpu                - Show CPU usage"
    echo "  mem                - Show memory usage"
    echo "  path               - List PATH entries"
    echo "  ip                 - Show public and local IP addresses"
    ;;
  esac
}


#
# ========================================================================
# macOS System Preferences
# ========================================================================

# Apply common macOS system preferences
function defaults_apply() {
  if ! is_macos; then
    log_error "Not running on macOS"
    return 1
  fi

  log_info "Applying macOS preferences..."

  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool TRUE
  defaults write com.apple.dock autohide -bool false
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock show-recents -bool false
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder _FXSortFoldersFirst -bool true

  # Restart affected applications
  for app in "Finder" "Dock"; do
    killall "$app" >/dev/null 2>&1
  done

  log_success "macOS preferences applied"
}

# The actual initialization happens in .zshrc via:
# has_command atuin && eval "$(atuin init zsh)"

# ========================================================================
# Config File Linking
# ========================================================================
setup_cli_tools() {
  info "Setting up CLI tools configuration..."

  # First, remove all existing symlinks and files that we'll be managing
  info "Cleaning up existing configurations..."
  for key in ${(k)DOTFILES_TO_SYMLINK_MAP}; do
    local dst="${DOTFILES_TO_SYMLINK_MAP[$key]}"

    # Remove existing symlink or file/directory
    if [[ -L "$dst" || -e "$dst" ]]; then
      rm -rf "$dst"
      success "Removed existing: $dst"
    fi
  done

  # Now create fresh symlinks
  info "Creating new symlinks..."
  for key in ${(k)DOTFILES_TO_SYMLINK_MAP}; do
    local src="$key"
    local dst="${DOTFILES_TO_SYMLINK_MAP[$key]}"
    local parent_dir=$(dirname "$dst")

    # Create parent directory if it doesn't exist
    ensure_dir "$parent_dir"

    # Create the symlink
    if [[ -e "$src" ]]; then
      ln -sf "$src" "$dst"
      success "Symlinked $dst -> $src source file"
    else
      warn "Source '$src' does not exist, skipping"
    fi
  done
}


# ========================================================================
# Function Exports
# ========================================================================

# Export the functions so they're available in other scripts
# export -f has_command is_macos is_linux is_apple_silicon is_rosetta sys defaults_apply 2>/dev/null || true
export has_command is_macos is_linux is_apple_silicon is_rosetta sys defaults_apply setup_cli_tools 2>/dev/null || true