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
typeset -g _DOTFILES="${DOTFILES:-$HOME/dotfiles}"
typeset -g _BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

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

# List all utility functions exported by this file
export function list_utils() {
  local util_funcs=$(functions | grep "^[a-z].*() {" | grep -v "^_" | sort)
  local count=$(echo "$util_funcs" | wc -l | tr -d ' ')

  log_info "Available utility functions ($count total):"
  echo "$util_funcs" | sed 's/() {.*//' | column
}

# ========================================================================
# Shell Detection and Environment
# ========================================================================

# Detect if running interactively
export function is_interactive() {
  [[ -o interactive ]]
}

# Detect if being sourced
export function is_sourced() {
  [[ "${FUNCNAME[1]-main}" != main ]]
}

# ========================================================================
# Command and System Detection
# ========================================================================

# Check if a command exists
export function has_command() {
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

# Install a tool if it's missing
export function ensure_tool_installed() {
  local tool="$1"
  local install_cmd="$2"
  local is_essential="${3:-false}"

  if ! has_command "$tool"; then
    if [[ "$is_essential" == "true" ]] || [[ "${INSTALL_MODE:-false}" == "true" ]]; then
      log_info "Installing missing $tool..."
      eval "$install_cmd"
      return $?
    else
      log_info "Tool '$tool' is not installed but not marked essential. Skipping."
      return 0
    fi
  fi
  return 0
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

# Alias for backward compatibility
export function dir_exists() {
  ensure_dir "$@"
}

# Create a backup of a file
export function backup_file() {
  local file="$1"
  local backup_dir="${2:-$_BACKUP_DIR}"

  if [[ -e "$file" ]]; then
    ensure_dir "$backup_dir"
    cp -a "$file" "$backup_dir/"
    log_success "Backed up $file to $backup_dir"
  else
    log_warn "File $file does not exist, skipping backup"
  fi
}

# Check if a file exists and is readable
export function file_exists() {
  [[ -r "$1" ]]
}

# Safe source - source a file if it exists
export function safe_source() {
  local file="$1"
  if file_exists "$file"; then
    source "$file"
    return 0
  else
    return 1
  fi
}
# ========================================================================
# Homebrew Installation Functions
# ========================================================================

# Initialize Homebrew path based on architecture
export function brew_init() {
  # Skip if brew is already in PATH
  if has_command brew; then
    return 0
  fi

  if is_apple_silicon; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
      log_success "Initialized Homebrew for Apple Silicon"
      return 0
    fi
  else
    if [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
      log_success "Initialized Homebrew for Intel Mac"
      return 0
    fi
  fi

  log_warn "Homebrew not found. Install it with: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  return 1
}

# Automatically initialize brew when this file is sourced
# brew_init

# uninstall brew
export function uninstall_brew() {
  if has_command brew; then
    log_info "Uninstalling Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
    log_success "Homebrew uninstalled"
  else
    log_warn "Homebrew is not installed"
  fi
}

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

# List PATH entries
export function path_list() {
  echo $PATH | tr ':' '\n' | nl
}

# Print the expanded PATH as a list
export function path_print() {
  echo "PATH components:"
  path_list | awk '{printf "  %2d: %s\n", $1, $2}'
}

# ========================================================================
# System & macOS Utilities
# ========================================================================
export function sys() {
  case "$1" in
  env-grep)
    echo "======== env vars =========="
    if [ -z "$2" ]; then
      printenv | sort | awk -F= '{ printf "%-30s %s\n", $1, $2 }'
    else
      printenv | sort | grep -i "$2" | awk -F= '{ printf "%-30s %s\n", $1, $2 }'
    fi
    echo "============================"
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
    echo "  killport <port>    - Kill process running on specified port"
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
export function setup_homebrew() {
  info "Setting up Homebrew..."

  if is_apple_silicon; then
    local brew_path="/opt/homebrew/bin/brew"
  else
    local brew_path="/usr/local/bin/brew"
  fi

  if [[ ! -x $brew_path ]]; then
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

  # Update Homebrew if running from an installation script
  if [[ "${INSTALL_MODE:-false}" == "true" ]]; then
    info "Updating Homebrew..."
    brew update

    # Install from Brewfile
    if [[ -f "$_DOTFILES/Brewfile" ]]; then
      info "Installing packages from Brewfile..."
      brew bundle install --verbose --global --all --force
    else
      warn "Brewfile not found at $_DOTFILES/Brewfile"
    fi
  fi
}

# Setup ZSH configuration
export function setup_zsh() {
  info "Setting up ZSH configuration..."

  # Use environment vars if set, fall back to internal vars if not
  local zdotdir_src="${ZDOTDIR_SRC:-$_DOTFILES/config/zsh}"

  # Create .zshenv in home directory pointing to dotfiles
  info "Creating .zshenv to point to dotfiles ZSH configuration"
  cat >"$HOME/.zshenv" <<EOF
# ZSH configuration bootstrapper
# Auto-generated by dotfiles setup
export ZDOTDIR="$zdotdir_src"
[[ -f "$zdotdir_src/.zshenv" ]] && source "$zdotdir_src/.zshenv"
EOF

  chmod 644 "$HOME/.zshenv"
  success "Created $HOME/.zshenv pointing to $zdotdir_src"
}

# ========================================================================
# Repository Verification
# ========================================================================

# Verify the dotfiles repository structure
export function verify_repo_structure() {
  info "Verifying dotfiles repository structure..."

  # Check if dotfiles directory exists
  if [[ ! -d "$_DOTFILES" ]]; then
    error "Dotfiles directory not found at $_DOTFILES"
    error "Please clone the repository first: git clone <repo-url> $_DOTFILES"
    return 1
  fi

  # Check if it's a git repository
  if [[ ! -d "$_DOTFILES/.git" ]]; then
    error "The dotfiles directory is not a git repository"
    error "Please clone the repository properly: git clone <repo-url> $_DOTFILES"
    return 1
  fi

  # Check for critical directories and files
  local missing_items=()

  [[ ! -f "$_DOTFILES/Brewfile" ]] && missing_items+=("Brewfile")
  [[ ! -d "$_DOTFILES/config" ]] && missing_items+=("config dir")
  [[ ! -d "$_DOTFILES/config/zsh" ]] && missing_items+=("config/zsh dir")
  [[ ! -f "$_DOTFILES/config/zsh/.zshenv" ]] && missing_items+=("config/zsh/.zshenv file")
  [[ ! -f "$_DOTFILES/config/zsh/.zprofile" ]] && missing_items+=("config/zsh/.zprofile file")
  [[ ! -f "$_DOTFILES/config/zsh/.zshrc" ]] && missing_items+=("config/zsh/.zshrc file")
  [[ ! -f "$_DOTFILES/config/zsh/utils.zsh" ]] && missing_items+=("config/zsh/utils.zsh file")

  if ((${#missing_items[@]} > 0)); then
    error "The dotfiles repository is missing critical components:"
    for item in "${missing_items[@]}"; do
      error "  - Missing $item"
    done
    error "Please ensure you've cloned the correct repository."
    return 1
  fi

  success "Repository structure verified successfully"
  return 0
}

# ========================================================================
# Setup CLI Tools and Configuration
# ========================================================================

# Setup CLI tools and configurations
export function setup_cli_tools() {
  info "Setting up CLI tools configuration..."

  # Get the correct path map based on environment vars or fallback
  local dotfiles="${DOTFILES:-$_DOTFILES}"

  # First, remove all existing symlinks and files that we'll be managing
  # Only do this in full installation mode to avoid disrupting the user's session
  if [[ "${INSTALL_MODE:-false}" == "true" ]]; then
    info "Cleaning up existing configurations..."
    for key in ${(k)DOTFILES_TO_SYMLINK_MAP}; do
      local dst="${DOTFILES_TO_SYMLINK_MAP[$key]}"

      # Remove existing symlink or file/directory
      if [[ -L "$dst" || -e "$dst" ]]; then
        rm -rf "$dst"
        success "Removed existing: $dst"
      fi
    done
  fi

  # Create symlinks for missing targets
  info "Creating missing symlinks..."
  for key in ${(k)DOTFILES_TO_SYMLINK_MAP}; do
    local src="$key"
    local dst="${DOTFILES_TO_SYMLINK_MAP[$key]}"
    local parent_dir=$(dirname "$dst")

    # Create parent directory if it doesn't exist
    ensure_dir "$parent_dir"

    # Create the symlink if it doesn't exist or is pointing to the wrong location
    if [[ ! -e "$dst" ]] || [[ "$(readlink "$dst")" != "$src" ]]; then
      if [[ -e "$src" ]]; then
        ln -sf "$src" "$dst"
        success "Symlinked $dst -> $src"
      else
        warn "Source '$src' does not exist, skipping"
      fi
    fi
  done
}

# Install essential tools
export function install_essential_tools() {
  info "Installing essential tools..."

  # Install Homebrew if needed
  if ! has_command "brew"; then
    setup_homebrew
  fi

  # Order of tool installation (prioritize essential tools)
  local tool_names=(starship nvim fzf eza zoxide atuin volta uv rustup go)

  # Install each tool if missing
  for tool_name in "${tool_names[@]}"; do
    local install_cmd="${TOOL_INSTALL_COMMANDS[$tool_name]}"
    local is_essential="${TOOL_IS_ESSENTIAL[$tool_name]}"
    ensure_tool_installed "$tool_name" "$install_cmd" "$is_essential"
  done

  success "Essential tools installed"
}
