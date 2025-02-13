#!/usr/bin/env bash
# Initialize dotfiles and system configuration
# Structured for config directory layout

# set -euo pipefail

# Configuration
# DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$HOME/dotfiles"
CONFIG_DIR="$HOME/.config"
# XDG_STATE_HOME="$HOME/.local/state"
# XDG_DATA_HOME="$HOME/.local/share"
# ZDOTDIR="$HOME/.config/zsh"

# Utility functions
log() { echo "==> $*" >&2; }
error() { echo "ERROR: $*" >&2; exit 1; }

# Create necessary directories
setup_directories() {
    log "Creating XDG directories..."
    mkdir -p "$CONFIG_DIR"
    
    # Create state directory for zsh history
    # mkdir -p "$XDG_STATE_HOME/zsh"
}

# Install Homebrew and packages
setup_homebrew() {
    if ! command -v brew >/dev/null; then
        log "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for the rest of the script
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
    
    if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
        log "Installing Homebrew packages..."
        brew bundle install --file="$DOTFILES_DIR/Brewfile" --all --force --verbose
        # brew bundle --file="$DOTFILES_DIR/Brewfile" --force 
    else
        error "Brewfile not found in $DOTFILES_DIR"
    fi
}

# Create symbolic links for config files
create_symlinks() {
    log "Creating symbolic links..."

    source "$DOTFILES_DIR/scripts/symlinks.sh"
    
    # # Function to create symlink with parent directory
    # link_config() {
    #     local src="$1"
    #     local dest="$2"
    #     mkdir -p "$(dirname "$dest")"
    #     ln -sf "$src" "$dest"
    # }
    
    # # Core configurations
    # link_config "$DOTFILES_DIR/config/zsh/.zshrc" "$HOME/.zshrc"
    # link_config "$DOTFILES_DIR/config/zsh/.zprofile" "$HOME/.zprofile"

    # # Config directory symlinks
    # declare -A configs=(
    #     ["aide"]="VSCode/User"           # VSCode settings
    #     ["atuin"]="atuin"
    #     ["bat"]="bat"
    #     ["cursor"]="cursor"
    #     ["ghostty"]="ghostty"
    #     ["git/.gitconfig"]="git/config"
    #     ["git/.gitignore"]="git/ignore"
    #     ["hammerspoon"]="../.hammerspoon" # Special case for home directory
    #     ["karabiner"]="karabiner"
    #     ["nvim"]="nvim"
    #     ["starship.toml"]="starship.toml"
    #     ["yazi"]="yazi"
    #     ["zed"]="zed"
    #     ["zellij"]="zellij"
    #     ["zsh-abbr"]="zsh-abbr"
    # )
    
    # for src in "${!configs[@]}"; do
    #     local dest=${configs[$src]}
    #     local full_src="$DOTFILES_DIR/config/$src"
    #     local full_dest="$CONFIG_DIR/$dest"
        
    #     if [[ -e "$full_src" ]]; then
    #         log "Linking $src to $dest"
    #         if [[ "$dest" == "../.hammerspoon" ]]; then
    #             link_config "$full_src" "$HOME/.hammerspoon"
    #         else
    #             link_config "$full_src" "$full_dest"
    #         fi
    #     fi
    # done
}

# Configure zshenv (2 files - ~/.zshenv and $DOTFILES/config/zsh/.zshenv)
setup_zsh() {
    if [[ ! -f "$CONFIG_DIR/git/config" ]]; then
        log "Configuring ~/.zshenv..."
        
        cat > "$HOME/.zshenv" << EOF
# Minimal stub for Zsh to load configs from ~/.config/zsh
# export ZDOTDIR="$ZDOTDIR"
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
EOF
    fi
}

# Configure git if not already set up
# setup_git() {
#     if [[ ! -f "$CONFIG_DIR/git/config" ]]; then
#         log "Configuring git..."
#         read -p "Enter git user name: " git_name
#         read -p "Enter git email: " git_email
        
#         mkdir -p "$CONFIG_DIR/git"
#         cat > "$CONFIG_DIR/git/config" << EOF
# [user]
#     name = $git_name
#     email = $git_email
# [init]
#     defaultBranch = main
# [core]
#     editor = nvim
# EOF
#     fi
# }

# Configure macOS defaults
setup_macos() {
    log "Configuring macOS defaults..."

    source "$DOTFILES_DIR/scripts/macos-defaults.sh"
    
    # Restart affected applications
    for app in "Finder" "Dock"; do
        killall "${app}" &>/dev/null || true
    done
}

# Backup existing configurations
# backup_existing() {
#     local backup_dir="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
#     local files_to_backup=(
#         "$HOME/.zshrc"
#         "$HOME/.hammerspoon"
#         "$CONFIG_DIR/git/config"
#     )
    
#     for file in "${files_to_backup[@]}"; do
#         if [[ -e "$file" ]] && [[ ! -L "$file" ]]; then
#             log "Backing up $file..."
#             mkdir -p "$backup_dir/$(dirname "${file#$HOME/}")"
#             mv "$file" "$backup_dir/${file#$HOME/}"
#         fi
#     done
# }

# Clean .DS_Store files
clean_ds_store() {
    log "Cleaning .DS_Store files..."
    find "$DOTFILES_DIR" -name ".DS_Store" -delete
}

# Main installation
main() {
    log "Starting dotfiles installation..."
    
    clean_ds_store
    # backup_existing
    setup_directories
    setup_homebrew
    create_symlinks
    # setup_git
    # setup_macos
    
    log "Installation complete! Please restart your shell and Finder."
    log "Your old configurations have been backed up to ~/.dotfiles_backup if they existed."
}

main "$@"
