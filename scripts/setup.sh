#!/usr/bin/env bash
# =============================================================================
# setup.sh - Dotfiles Setup Script
# =============================================================================
# Idempotent setup script for macOS dotfiles that:
# - Creates necessary XDG directories
# - Symlinks configuration files
# - Optionally installs Homebrew and packages
# - Optionally configures macOS preferences

set -euo pipefail

# =============================================================================
# Environment Configuration
# =============================================================================
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"
export BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Default flag values
NO_BREW=false
NO_MACOS=false
MINIMAL=false
UPDATE=false
DRY_RUN=false
VERBOSE=false

# =============================================================================
# Utility Functions
# =============================================================================
log() { printf "%b\n" "$*" >&2; }
info() { log "\033[34m[INFO]\033[0m $*"; }
warn() { log "\033[33m[WARN]\033[0m $*"; }
error() { log "\033[31m[ERROR]\033[0m $*"; }
success() { log "\033[32m[OK]\033[0m $*"; }
separator() { echo -e "\n\033[90m----------------------------------------\033[0m\n"; }

# System detection
is_macos() { [[ "$OSTYPE" == darwin* ]]; }
is_apple_silicon() { [[ "$(uname -m)" == "arm64" ]]; }
has_command() { command -v "$1" >/dev/null 2>&1; }

# File operations
backup_file() {
  local file="$1"
  local backup="$BACKUP_DIR/$(basename "$file")"
  local backup_dir="$(dirname "$backup")"
  
  if [[ -e "$file" && ! -L "$file" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
      info "Would backup $file to $backup"
      return 0
    fi
    
    mkdir -p "$backup_dir"
    info "Backing up $file to $backup"
    cp -R "$file" "$backup"
  elif [[ -L "$file" ]]; then
    # Only backup symlinks if they're pointing to a different target
    local current_target="$(readlink "$file")"
    if [[ "$current_target" != "$2" ]]; then
      if [[ "$DRY_RUN" == "true" ]]; then
        info "Would backup symlink $file → $current_target to $backup"
        return 0
      fi
      
      mkdir -p "$backup_dir"
      info "Backing up symlink $file → $current_target to $backup"
      cp -R "$file" "$backup"
    fi
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
    if [[ "$DRY_RUN" == "true" ]]; then
      info "Would create directory: $dst_dir"
    else
      info "Creating directory: $dst_dir"
      mkdir -p "$dst_dir"
    fi
  fi

  # Check if destination is already a symlink to the source
  if [[ -L "$dst_symlink" ]]; then
    local current_target="$(readlink "$dst_symlink")"
    if [[ "$current_target" == "$src_orig" ]]; then
      if [[ "$VERBOSE" == "true" ]]; then
        info "Symlink already exists and points to the correct location: $dst_symlink → $src_orig"
      fi
      return 0
    else
      # Backup existing symlink
      backup_file "$dst_symlink" "$src_orig"
      if [[ "$DRY_RUN" == "true" ]]; then
        info "Would update symlink $dst_symlink → $src_orig"
      else
        info "Updating symlink $dst_symlink → $src_orig"
        ln -sf "$src_orig" "$dst_symlink"
      fi
    fi
  elif [[ -e "$dst_symlink" ]]; then
    # Backup existing file/directory
    backup_file "$dst_symlink" "$src_orig"
    if [[ "$DRY_RUN" == "true" ]]; then
      info "Would replace $dst_symlink with symlink to $src_orig"
    else
      info "Replacing $dst_symlink with symlink to $src_orig"
      rm -rf "$dst_symlink"
      ln -sf "$src_orig" "$dst_symlink"
    fi
  else
    # Create new symlink
    if [[ "$DRY_RUN" == "true" ]]; then
      info "Would create symlink $dst_symlink → $src_orig"
    else
      info "Creating symlink $dst_symlink → $src_orig"
      ln -sf "$src_orig" "$dst_symlink"
    fi
  fi
}

ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
      info "Would create directory: $dir"
    else
      info "Creating directory: $dir"
      mkdir -p "$dir"
    fi
  elif [[ "$VERBOSE" == "true" ]]; then
    info "Directory already exists: $dir"
  fi
}

# =============================================================================
# System Check
# =============================================================================
check_system() {
  info "Checking system requirements..."

  # Check if running on macOS
  if ! is_macos; then
    error "This script is designed for macOS only."
    exit 1
  fi

  # Check for Apple Silicon
  if ! is_apple_silicon; then
    warn "This configuration is optimized for Apple Silicon Macs."
    warn "Some features may not work correctly on Intel Macs."
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      error "Aborting installation."
      exit 1
    fi
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

  if [[ ${#missing_commands[@]} -gt 0 ]]; then
    error "Required commands not found: ${missing_commands[*]}"
    error "Please install the missing commands and try again."
    exit 1
  fi

  success "System requirements met."
}

# =============================================================================
# Setup XDG Directories
# =============================================================================
setup_xdg_dirs() {
  info "Setting up XDG directories..."
  
  ensure_dir "$XDG_CONFIG_HOME"
  ensure_dir "$XDG_CACHE_HOME"
  ensure_dir "$XDG_DATA_HOME"
  ensure_dir "$XDG_STATE_HOME"
  
  success "XDG directories setup complete."
}

# =============================================================================
# Setup ZSH
# =============================================================================
setup_zsh() {
  info "Setting up ZSH configuration..."
  
  # Create ZDOTDIR
  ensure_dir "$ZDOTDIR"
  
  # Setup .zshenv in home directory
  local zshenv="$HOME/.zshenv"
  if [[ "$DRY_RUN" == "true" ]]; then
    info "Would create $zshenv with content pointing to $ZDOTDIR"
  else
    cat > "$zshenv" << EOL
# Generated by dotfiles setup.sh
export ZDOTDIR="$ZDOTDIR"
[[ -f "\$ZDOTDIR/.zshenv" ]] && source "\$ZDOTDIR/.zshenv"
EOL
    success "Created $zshenv pointing to $ZDOTDIR"
  fi
  
  # Symlink ZSH config files
  if [[ -d "$DOTFILES/config/zsh" ]]; then
    make_link "$DOTFILES/config/zsh" "$ZDOTDIR"
  else
    warn "ZSH config directory not found at $DOTFILES/config/zsh"
  fi
  
  success "ZSH configuration setup complete."
}

# =============================================================================
# Setup Homebrew
# =============================================================================
setup_homebrew() {
  if [[ "$NO_BREW" == "true" ]]; then
    info "Skipping Homebrew setup (--no-brew flag used)."
    return 0
  fi
  
  info "Setting up Homebrew..."
  
  # Install Homebrew if not already installed
  if ! has_command brew; then
    if [[ "$DRY_RUN" == "true" ]]; then
      info "Would install Homebrew."
    else
      info "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      
      # Add Homebrew to PATH for this session
      if is_apple_silicon; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      else
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    fi
  else
    info "Homebrew is already installed."
  fi
  
  # Update Homebrew
  if [[ "$DRY_RUN" == "true" ]]; then
    info "Would update Homebrew."
  else
    info "Updating Homebrew..."
    brew update
  fi
  
  # Install from Brewfile
  local brewfile="$DOTFILES/Brewfile.core"
  if [[ ! "$MINIMAL" == "true" && -f "$DOTFILES/Brewfile.full" ]]; then
    brewfile="$DOTFILES/Brewfile.full"
  fi
  
  if [[ -f "$brewfile" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
      info "Would install packages from $brewfile."
    else
      info "Installing packages from $brewfile..."
      brew bundle install --file="$brewfile" --no-lock
    fi
  else
    warn "Brewfile not found at $brewfile"
  fi
  
  success "Homebrew setup complete."
}

# =============================================================================
# Setup Configuration Files
# =============================================================================
setup_configs() {
  info "Setting up configuration files..."
  
  # List of config directories to symlink directly
  # Format: "source_dir:target_dir"
  local config_dirs=(
    "aerospace:aerospace"
    "bat:bat"
    "ghostty:ghostty"
    "git:git"
    "nvim:nvim"
    "starship:starship"
    "yazi:yazi"
    "zellij:zellij"
    "hammerspoon:hammerspoon"
  )
  
  # Symlink each config directory
  for dir_pair in "${config_dirs[@]}"; do
    IFS=':' read -r src_dir target_dir <<< "$dir_pair"
    
    local src_path="$DOTFILES/config/$src_dir"
    local target_path="$XDG_CONFIG_HOME/$target_dir"
    
    if [[ -d "$src_path" ]]; then
      make_link "$src_path" "$target_path"
    else
      warn "Source directory not found: $src_path"
    fi
  done
  
  # Special handling for specific configs
  
  # Hammerspoon (non-XDG)
  if [[ -f "$DOTFILES/config/hammerspoon/init.lua" ]]; then
    ensure_dir "$HOME/.hammerspoon"
    make_link "$DOTFILES/config/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"
  fi
  
  # VS Code
  if [[ -d "$DOTFILES/config/vscode" ]]; then
    ensure_dir "$HOME/Library/Application Support/Code/User"
    
    if [[ -f "$DOTFILES/config/vscode/settings.json" ]]; then
      make_link "$DOTFILES/config/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
    fi
    
    if [[ -f "$DOTFILES/config/vscode/keybindings.json" ]]; then
      make_link "$DOTFILES/config/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
    fi
  fi
  
  # Cursor
  if [[ -d "$DOTFILES/config/cursor" ]]; then
    ensure_dir "$HOME/Library/Application Support/Cursor/User"
    
    if [[ -f "$DOTFILES/config/cursor/settings.json" ]]; then
      make_link "$DOTFILES/config/cursor/settings.json" "$HOME/Library/Application Support/Cursor/User/settings.json"
    fi
    
    if [[ -f "$DOTFILES/config/cursor/keybindings.json" ]]; then
      make_link "$DOTFILES/config/cursor/keybindings.json" "$HOME/Library/Application Support/Cursor/User/keybindings.json"
    fi
  fi
  
  # Claude Desktop
  if [[ -d "$DOTFILES/config/ai/claude" ]]; then
    ensure_dir "$HOME/Library/Application Support/Claude"
    
    if [[ -f "$DOTFILES/config/ai/claude/claude_desktop_config.json" ]]; then
      make_link "$DOTFILES/config/ai/claude/claude_desktop_config.json" "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
    fi
  fi
  
  success "Configuration files setup complete."
}

# =============================================================================
# Setup macOS Preferences
# =============================================================================
setup_macos_prefs() {
  if [[ "$NO_MACOS" == "true" ]]; then
    info "Skipping macOS preferences setup (--no-macos flag used)."
    return 0
  fi
  
  info "Setting up macOS preferences..."
  
  if [[ "$DRY_RUN" == "true" ]]; then
    info "Would configure macOS preferences."
    return 0
  fi
  
  # Check if we have a macOS preferences script
  if [[ -f "$DOTFILES/config/darwin/setup_macos.sh" ]]; then
    info "Running macOS preferences script..."
    # Source the script rather than executing it to maintain the environment
    source "$DOTFILES/config/darwin/setup_macos.sh"
  else
    warn "macOS preferences script not found at $DOTFILES/config/darwin/setup_macos.sh"
    warn "Skipping macOS preferences setup."
    return 0
  fi
  
  success "macOS preferences setup complete."
}

# =============================================================================
# Parse Arguments
# =============================================================================
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
      --update)
        UPDATE=true
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --verbose)
        VERBOSE=true
        shift
        ;;
      --help)
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --no-brew     Skip Homebrew installation and updates"
        echo "  --no-macos    Skip macOS preferences configuration"
        echo "  --minimal     Install only essential configurations"
        echo "  --update      Update existing installation"
        echo "  --dry-run     Show what would be done without making changes"
        echo "  --verbose     Show detailed output"
        echo "  --help        Show this help message"
        exit 0
        ;;
      *)
        error "Unknown option: $1"
        echo "Use --help to see available options."
        exit 1
        ;;
    esac
  done
}

# =============================================================================
# Main Function
# =============================================================================
main() {
  separator
  info "Starting dotfiles setup for macOS..."
  
  if [[ "$DRY_RUN" == "true" ]]; then
    info "Running in dry run mode. No changes will be made."
  fi
  
  # Start timer
  local start_time=$(date +%s)
  
  # Perform system check
  check_system
  
  # Setup XDG directories
  setup_xdg_dirs
  
  # Setup ZSH
  setup_zsh
  
  # Setup config files
  setup_configs
  
  # Setup Homebrew
  setup_homebrew
  
  # Setup macOS preferences
  setup_macos_prefs
  
  # Calculate time taken
  local end_time=$(date +%s)
  local time_taken=$((end_time - start_time))
  local minutes=$((time_taken / 60))
  local seconds=$((time_taken % 60))
  
  separator
  success "Dotfiles setup complete! 🎉"
  info "Time taken: ${minutes}m ${seconds}s"
  
  if [[ -d "$BACKUP_DIR" && "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
    local backup_size=$(du -sh "$BACKUP_DIR" | cut -f1)
    info "Backup created at $BACKUP_DIR ($backup_size)"
  fi
  
  info "Please log out and log back in, or restart your computer for all changes to take effect."
  info "To finish setting up your shell, run: exec zsh"
  separator
}

# Parse command-line arguments
parse_args "$@"

# Run the script
main