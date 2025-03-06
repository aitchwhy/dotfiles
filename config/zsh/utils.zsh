#!/usr/bin/env zsh
# ========================================================================
# ZSH Utils - Common utilities for shell scripts and configurations
# ========================================================================
# This file contains utility functions that are shared across multiple
# shell scripts and configuration files.

# ========================================================================
# Core Environment Variables
# ========================================================================
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export ZDOTDIR_TARGET="$XDG_CONFIG_HOME/zsh"
export ZDOTDIR_SRC="$DOTFILES/config/zsh"
export BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# ========================================================================
# Dotfiles Symlink Map Configuration
# ========================================================================

# This defines the mapping between dotfiles source locations and their
# target locations in the user's home directory. It's used by the installation
# script and other dotfiles management tools.

declare -gA DOTFILES_TO_SYMLINK_MAP=(
  # Git configurations
  ["$DOTFILES/config/git/gitconfig"]="$HOME/.gitconfig"
  ["$DOTFILES/config/git/gitignore"]="$HOME/.gitignore"
  ["$DOTFILES/config/git/gitattributes"]="$HOME/.gitattributes"
  ["$DOTFILES/config/git/gitmessage"]="$HOME/.gitmessage"

  # XDG configurations
  ["$DOTFILES/config/starship.toml"]="$XDG_CONFIG_HOME/starship.toml"
  ["$DOTFILES/config/karabiner/karabiner.json"]="$XDG_CONFIG_HOME/karabiner/karabiner.json"
  ["$DOTFILES/config/nvim"]="$XDG_CONFIG_HOME/nvim"
  ["$DOTFILES/config/ghostty"]="$XDG_CONFIG_HOME/ghostty"
  ["$DOTFILES/config/atuin"]="$XDG_CONFIG_HOME/atuin"
  ["$DOTFILES/config/bat"]="$XDG_CONFIG_HOME/bat"
  ["$DOTFILES/config/lazygit"]="$XDG_CONFIG_HOME/lazygit"
  ["$DOTFILES/config/zellij"]="$XDG_CONFIG_HOME/zellij"
  ["$DOTFILES/config/zed"]="$XDG_CONFIG_HOME/zed"
  ["$DOTFILES/config/espanso"]="$XDG_CONFIG_HOME/espanso"
  ["$DOTFILES/config/yazi"]="$XDG_CONFIG_HOME/yazi"
  ["$DOTFILES/config/warp/keybindings.yaml"]="$XDG_CONFIG_HOME/warp/keybindings.yaml"

  # Editor configurations
  ["$DOTFILES/config/vscode/settings.json"]="$HOME/Library/Application Support/Code/User/settings.json"
  ["$DOTFILES/config/vscode/keybindings.json"]="$HOME/Library/Application Support/Code/User/keybindings.json"
  ["$DOTFILES/config/cursor/settings.json"]="$HOME/Library/Application Support/Cursor/User/settings.json"
  ["$DOTFILES/config/cursor/keybindings.json"]="$HOME/Library/Application Support/Cursor/User/keybindings.json"

  # macOS-specific configurations
  ["$DOTFILES/config/hammerspoon"]="$HOME/.hammerspoon"

  # AI tools configurations
  ["$DOTFILES/config/ai/claude/claude_desktop_config.json"]="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
  ["$DOTFILES/config/ai/cline/cline_mcp_settings.json"]="$HOME/Library/Application Support/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"
)

# Export the map for use in other scripts
export DOTFILES_TO_SYMLINK_MAP

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
# Core Installation Functions
# ========================================================================

# Setup Homebrew and install packages
setup_homebrew() {
  info "Setting up Homebrew..."

  if [[ ! -x /opt/homebrew/bin/brew ]] && [[ ! -x /usr/local/bin/brew ]]; then
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
  fi

  # Install from Brewfile
  if [[ -f "$DOTFILES/Brewfile" ]]; then
    if [[ "${INSTALL_MODE:-false}" == "true" ]]; then
      info "Installing packages from Brewfile..."
      brew bundle install --verbose --global --all --force
    fi
  else
    warn "Brewfile not found at $DOTFILES/Brewfile"
  fi
}

# Setup ZSH configuration
setup_zsh() {
  info "Setting up ZSH configuration..."

  # Create .zshenv in home directory pointing to dotfiles
  info "Creating .zshenv to point to dotfiles ZSH configuration"
  cat >"$HOME/.zshenv" <<EOF
# ZSH configuration bootstrapper
# Auto-generated by dotfiles setup
export ZDOTDIR="$ZDOTDIR_SRC"
[[ -f "$ZDOTDIR_SRC/.zshenv" ]] && source "$ZDOTDIR_SRC/.zshenv"
EOF

  chmod 644 "$HOME/.zshenv"
  success "Created $HOME/.zshenv pointing to $ZDOTDIR_SRC"
}

# Apply macOS System Preferences
setup_macos_preferences() {
  if ! is_macos; then
    warn "Not running on macOS, skipping preferences"
    return 1
  fi

  info "Configuring macOS system preferences..."

  # Faster key repeat
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 15

  # Disable press-and-hold for keys in favor of key repeat
  default write NSGlobalDomain ApplePressAndHoldEnabled -bool false

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

# Install a tool if it's missing
function ensure_tool_installed() {
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

# Setup CLI tools and configurations
# ========================================================================
# Config File Linking
# ========================================================================
setup_cli_tools() {
  info "Setting up CLI tools configuration..."

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

# Check system requirements
check_requirements() {
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

# Install essential tools
install_essential_tools() {
  info "Installing essential tools..."

  # Install Homebrew if needed
  if ! has_command "brew"; then
    setup_homebrew
  fi

  # Define installation commands for tools
  declare -A TOOL_INSTALL_COMMANDS=(
    [starship]="curl -sS https://starship.rs/install.sh | sh"
    [git]="brew install git"
    [nvim]="brew install neovim"
    [fzf]="brew install fzf"
    [eza]="brew install eza"
    [zoxide]="brew install zoxide"
    [atuin]="curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh"
    [volta]="curl https://get.volta.sh | bash"
    [uv]="curl -LsSf https://astral.sh/uv/install.sh | sh"
    [rustup]="curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    [go]="brew install go"
  )

  # Define which tools are essential
  declare -A TOOL_IS_ESSENTIAL=(
    [starship]=true
    [git]=true
    [nvim]=false
    [fzf]=false
    [eza]=false
    [zoxide]=false
    [atuin]=false
    [volta]=false
    [uv]=false
    [rustup]=false
    [go]=false
  )

  # Order of tool installation (prioritize essential tools)
  local tool_names=(starship git nvim fzf eza zoxide atuin volta uv rustup go)

  # Install each tool if missing
  for tool_name in "${tool_names[@]}"; do
    local install_cmd="${TOOL_INSTALL_COMMANDS[$tool_name]}"
    local is_essential="${TOOL_IS_ESSENTIAL[$tool_name]}"
    ensure_tool_installed "$tool_name" "$install_cmd" "$is_essential"
  done

  success "Essential tools installed"
}


# ========================================================================
# Function Exports
# ========================================================================

# Export the functions so they're available in other scripts
# export -f has_command is_macos is_linux is_apple_silicon is_rosetta sys defaults_apply 2>/dev/null || true
export has_command is_macos is_linux is_apple_silicon is_rosetta sys defaults_apply setup_cli_tools 2>/dev/null || true
