#!/usr/bin/env zsh

# ========================================================================
# ZSH-Specific Helper Functions
# ========================================================================

# ========================================================================
# ZSH Environment Functions
# ========================================================================

# Reload the ZSH configuration
function reload_zsh() {
  if [[ -f "$ZDOTDIR/.zshrc" ]]; then
    source "$ZDOTDIR/.zshrc"
    echo "ZSH configuration reloaded."
  else
    echo "Error: .zshrc not found at $ZDOTDIR/.zshrc"
  fi
}

# Check if a ZSH plugin is loaded
function zsh_plugin_loaded() {
  local plugin_name="$1"
  if [[ "${plugins[(r)$plugin_name]}" == "$plugin_name" ]]; then
    return 0
  fi
  return 1
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

# ========================================================================
# XDG Base Directory Support Functions
# ========================================================================

# Ensure XDG Base Directory Specification is respected
function ensure_xdg_dirs() {
  export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
  export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
  export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
  export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
  
  # Create directories if they don't exist
  mkdir -p "$XDG_CONFIG_HOME"
  mkdir -p "$XDG_CACHE_HOME"
  mkdir -p "$XDG_DATA_HOME"
  mkdir -p "$XDG_STATE_HOME"
}

# ========================================================================
# ZSH Plugin Management Functions
# ========================================================================

# Check if a plugin directory exists
function plugin_dir_exists() {
  local plugin_dir="$1"
  [[ -d "$plugin_dir" ]]
}

# Safely source a file if it exists
function safe_source() {
  local file="$1"
  [[ -f "$file" ]] && source "$file"
}

# ========================================================================
# macOS Utils for ZSH
# ========================================================================

# Open a file or directory in the macOS Finder
function finder() {
  local path="${1:-.}"
  open -a Finder "$path"
}

# Show/hide hidden files in macOS Finder
function toggle_hidden_files() {
  local current
  current=$(defaults read com.apple.finder AppleShowAllFiles)
  defaults write com.apple.finder AppleShowAllFiles $((!current))
  killall Finder
  echo "Finder hidden files: $((!current))"
}

# Open the current directory in VSCode
function code_here() {
  if has_command "code"; then
    code .
  elif has_command "cursor"; then
    cursor .
  else
    echo "Neither VSCode nor Cursor is installed."
  fi
}

# Open the current directory in the default terminal
function term_here() {
  if has_command "open"; then
    open -a Terminal .
  fi
}

# ========================================================================
# Apple Silicon Specific Functions
# ========================================================================

# Run command with Rosetta 2 (x86_64 architecture)
function rosetta() {
  if [[ "$(uname -m)" == "arm64" ]]; then
    arch -x86_64 "$@"
  else
    echo "Not running on Apple Silicon, executing normally."
    "$@"
  fi
}

# Check if running under Rosetta 2
function is_rosetta() {
  if [[ "$(uname -m)" == "arm64" ]]; then
    if [[ "$(sysctl -n sysctl.proc_translated 2>/dev/null)" == "1" ]]; then
      return 0  # Running under Rosetta
    fi
  fi
  return 1  # Not running under Rosetta
}

# Check brew prefix based on architecture
function get_brew_prefix() {
  if [[ "$(uname -m)" == "arm64" ]]; then
    echo "/opt/homebrew"
  else
    echo "/usr/local"
  fi
}

# ========================================================================
# Homebrew Helper Functions
# ========================================================================

# Initialize Homebrew environment
function init_homebrew() {
  if [[ "$(uname -m)" == "arm64" ]]; then
    if [[ -f /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
      return 0
    fi
  else
    if [[ -f /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
      return 0
    fi
  fi
  return 1
}

# Install a Homebrew formula if it's not already installed
function brew_install_if_missing() {
  local formula="$1"
  if ! brew list "$formula" &>/dev/null; then
    brew install "$formula"
  else
    echo "Formula '$formula' is already installed."
  fi
}

# Check if a cask is installed via Homebrew
function brew_cask_installed() {
  local cask="$1"
  brew list --cask "$cask" &>/dev/null
}
