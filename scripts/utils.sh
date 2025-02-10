#!/bin/sh
# shell-utils.sh - A collection of POSIX-compliant shell utilities for both bash and zsh
# Can be sourced in scripts or shell rc files

################################################################################
# CONSTANTS AND DEFAULTS
################################################################################

# Default paths (can be overridden before sourcing)
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/.backups}"

# Ensure backup directory exists
[ ! -d "$BACKUP_DIR" ] && mkdir -p "$BACKUP_DIR"

################################################################################
# FORMATTING AND LOGGING
################################################################################

# ANSI color codes (if terminal supports it)
if [ -t 1 ]; then
    RED=$(printf '\033[31m')
    GREEN=$(printf '\033[32m')
    YELLOW=$(printf '\033[33m')
    BLUE=$(printf '\033[34m')
    BOLD=$(printf '\033[1m')
    RESET=$(printf '\033[0m')
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    BOLD=""
    RESET=""
fi

# Logging functions
log_info() {
    printf '%s[INFO]%s %s\n' "${BLUE}" "${RESET}" "$*"
}

log_success() {
    printf '%s[SUCCESS]%s %s\n' "${GREEN}" "${RESET}" "$*"
}

log_warning() {
    printf '%s[WARNING]%s %s\n' "${YELLOW}" "${RESET}" "$*" >&2
}

log_error() {
    printf '%s[ERROR]%s %s\n' "${RED}" "${RESET}" "$*" >&2
}

# Progress indicator
show_progress() {
    printf '%s→%s %s...\n' "${BLUE}" "${RESET}" "$*"
}

################################################################################
# FILE AND DIRECTORY OPERATIONS
################################################################################

# Create timestamped backup of a file or directory
backup_item() {
    [ $# -ne 1 ] && log_error "Usage: backup_item <path>" && return 1
    local item="$1"
    local timestamp=$(date +'%Y%m%d_%H%M%S')
    local backup_path="$BACKUP_DIR/$(basename "$item").$timestamp"
    
    if [ -e "$item" ] || [ -L "$item" ]; then
        if cp -aL "$item" "$backup_path"; then
            log_info "Backed up $item to $backup_path"
            return 0
        else
            log_error "Failed to backup $item"
            return 1
        fi
    fi
}

# Safe symlink creation with backup
safe_link() {
    [ $# -ne 2 ] && log_error "Usage: safe_link <source> <target>" && return 1
    local src="$1"
    local target="$2"

    # Ensure source exists
    if [ ! -e "$src" ]; then
        log_error "Source does not exist: $src"
        return 1
    fi

    # Create parent directory if needed
    mkdir -p "$(dirname "$target")"

    # Handle existing target
    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
            log_info "Link already exists and is correct: $target -> $src"
            return 0
        fi
        backup_item "$target"
    fi

    # Create new symlink
    if ln -sf "$src" "$target"; then
        log_success "Created symlink: $target -> $src"
        return 0
    else
        log_error "Failed to create symlink: $target -> $src"
        return 1
    fi
}

################################################################################
# SYSTEM AND ENVIRONMENT DETECTION
################################################################################

# OS detection
is_macos() {
    [ "$(uname)" = "Darwin" ]
}

is_linux() {
    [ "$(uname)" = "Linux" ]
}

# Architecture detection
is_arm64() {
    [ "$(uname -m)" = "arm64" ] || [ "$(uname -m)" = "aarch64" ]
}

is_x86_64() {
    [ "$(uname -m)" = "x86_64" ]
}

# Shell detection
is_zsh() {
    [ -n "$ZSH_VERSION" ]
}

is_bash() {
    [ -n "$BASH_VERSION" ]
}

################################################################################
# PACKAGE MANAGEMENT
################################################################################

# Homebrew utilities
has_brew() {
    command -v brew >/dev/null 2>&1
}

ensure_brew() {
    if ! has_brew; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add to PATH for current session if installed
        if is_arm64; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
}

update_brew() {
    if has_brew; then
        log_info "Updating Homebrew..."
        brew update
        brew upgrade
        brew cleanup
    fi
}

################################################################################
# MACOS SPECIFIC UTILITIES
################################################################################

# Apply common macOS system preferences
apply_macos_prefs() {
    if ! is_macos; then
        log_error "Not running on macOS"
        return 1
    fi

    log_info "Applying macOS preferences..."
    
    # Finder preferences
    defaults write com.apple.finder AppleShowAllFiles -bool true
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true

    # Dock preferences
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock autohide-delay -float 0
    defaults write com.apple.dock show-recents -bool false

    # Keyboard preferences
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

    # Restart affected applications
    for app in "Finder" "Dock"; do
        killall "$app" >/dev/null 2>&1
    done

    log_success "macOS preferences applied"
}

################################################################################
# SHELL ENVIRONMENT SETUP
################################################################################

# Set up ZSH configuration directory
setup_zsh_env() {
    local zdotdir="${ZDOTDIR:-$CONFIG_DIR/zsh}"
    
    # Create config directory
    mkdir -p "$zdotdir"
    
    # Create minimal .zshenv if it doesn't exist
    if [ ! -f "$HOME/.zshenv" ]; then
        cat > "$HOME/.zshenv" <<EOF
# Set ZSH configuration directory
export ZDOTDIR="$zdotdir"
[ -f "\$ZDOTDIR/.zshenv" ] && source "\$ZDOTDIR/.zshenv"
EOF
        log_success "Created .zshenv pointing to $zdotdir"
    fi
}

# Change shell to specified shell
change_shell() {
    [ $# -ne 1 ] && log_error "Usage: change_shell <shell_path>" && return 1
    local new_shell="$1"

    # Verify shell exists and is executable
    if [ ! -x "$new_shell" ]; then
        log_error "Shell does not exist or is not executable: $new_shell"
        return 1
    }

    # Add to /etc/shells if needed
    if ! grep -Fxq "$new_shell" /etc/shells; then
        log_info "Adding $new_shell to /etc/shells"
        echo "$new_shell" | sudo tee -a /etc/shells >/dev/null
    fi

    # Change shell if different from current
    if [ "$SHELL" != "$new_shell" ]; then
        log_info "Changing shell to $new_shell"
        chsh -s "$new_shell" || log_error "Failed to change shell. Try: chsh -s $new_shell"
    else
        log_info "Shell is already set to $new_shell"
    fi
}

################################################################################
# DOTFILES MANAGEMENT
################################################################################

# Sync dotfiles repository
sync_dotfiles() {
    [ $# -ne 1 ] && log_error "Usage: sync_dotfiles <repo_url>" && return 1
    local repo_url="$1"

    if [ -d "$DOTFILES_DIR/.git" ]; then
        log_info "Updating dotfiles repository..."
        git -C "$DOTFILES_DIR" pull --ff-only || log_warning "Could not pull latest changes"
    else
        log_info "Cloning dotfiles repository..."
        git clone "$repo_url" "$DOTFILES_DIR"
    fi
}

# Export installed packages list
export_packages() {
    local timestamp=$(date +'%Y%m%d_%H%M%S')
    local output_dir="$BACKUP_DIR/packages_$timestamp"
    mkdir -p "$output_dir"

    log_info "Exporting package lists..."

    if has_brew; then
        brew bundle dump --file="$output_dir/Brewfile" --describe
        log_success "Exported Homebrew packages to $output_dir/Brewfile"
    fi

    if is_macos; then
        system_profiler SPApplicationsDataType > "$output_dir/applications.txt"
        log_success "Exported system applications to $output_dir/applications.txt"
    fi
}

################################################################################
# END OF FILE
################################################################################
