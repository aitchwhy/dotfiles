#!/usr/bin/env bash
# Initialize dotfiles and system configuration
# Structured for config directory layout

set -euo pipefail

# Configuration
# DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# DOTFILES="$HOME/dotfiles"
# CONFIG="$HOME/.config"
# XDG_STATE_HOME="$HOME/.local/state"
# XDG_DATA_HOME="$HOME/.local/share"
# ZDOTDIR="$HOME/.config/zsh"


# export XDG_CONFIG_HOME="$HOME/.config"
# export XDG_CACHE_HOME="$HOME/.cache"
# export XDG_DATA_HOME="$HOME/.local/share"
# export XDG_STATE_HOME="$HOME/.local/state"
# export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

export DOTFILES="$HOME/dotfiles"


# Utility functions
log() { echo "==> $*" >&2; }
error() { echo "ERROR: $*" >&2; exit 1; }

# Install Homebrew and packages
setup_homebrew() {
    if ! command -v brew >/dev/null; then
        log "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # # Add Homebrew to PATH for the rest of the script
        # if [[ -f /opt/homebrew/bin/brew ]]; then
        #     eval "$(/opt/homebrew/bin/brew shellenv)"
        # fi
    fi
    
    # if [[ -f "$DOTFILES/Brewfile" ]]; then
    #     log "Installing Homebrew packages..."
    #     brew bundle install --file="$DOTFILES/Brewfile" --no-vscode --force --verbose
    #     # brew bundle --file="$DOTFILES/Brewfile" --force 
    # else
    #     error "Brewfile not found in $DOTFILES"
    # fi
}



# # Create symbolic links for config files
# create_symlinks() {
#     log "Creating symbolic links..."

#     source "$DOTFILES/scripts/symlinks.sh"
    
#     # # Function to create symlink with parent directory
#     # link_config() {
#     #     local src="$1"
#     #     local dest="$2"
#     #     mkdir -p "$(dirname "$dest")"
#     #     ln -sf "$src" "$dest"
#     # }
    
#     # # Core configurations
#     # link_config "$DOTFILES/config/zsh/.zshrc" "$HOME/.zshrc"
#     # link_config "$DOTFILES/config/zsh/.zprofile" "$HOME/.zprofile"

#     # # Config directory symlinks
#     # declare -A configs=(
#     #     ["aide"]="VSCode/User"           # VSCode settings
#     #     ["atuin"]="atuin"
#     #     ["bat"]="bat"
#     #     ["cursor"]="cursor"
#     #     ["ghostty"]="ghostty"
#     #     ["git/.gitconfig"]="git/config"
#     #     ["git/.gitignore"]="git/ignore"
#     #     ["hammerspoon"]="../.hammerspoon" # Special case for home directory
#     #     ["karabiner"]="karabiner"
#     #     ["nvim"]="nvim"
#     #     ["starship.toml"]="starship.toml"
#     #     ["yazi"]="yazi"
#     #     ["zed"]="zed"
#     #     ["zellij"]="zellij"
#     #     ["zsh-abbr"]="zsh-abbr"
#     # )
    
#     # for src in "${!configs[@]}"; do
#     #     local dest=${configs[$src]}
#     #     local full_src="$DOTFILES/config/$src"
#     #     local full_dest="$CONFIG_DIR/$dest"
        
#     #     if [[ -e "$full_src" ]]; then
#     #         log "Linking $src to $dest"
#     #         if [[ "$dest" == "../.hammerspoon" ]]; then
#     #             link_config "$full_src" "$HOME/.hammerspoon"
#     #         else
#     #             link_config "$full_src" "$full_dest"
#     #         fi
#     #     fi
#     # done
# }
# # Function to create symlink with parent directory
# link_config() {
#     local src="$1"
#     local dest="$2"
#     mkdir -p "$(dirname "$dest")"
#     ln -sf "$src" "$dest"
# }

# Configure zshenv (2 files - ~/.zshenv and $DOTFILES/config/zsh/.zshenv)
setup_zsh() {
    if [[ ! -f "$HOME/.zshenv" ]]; then
        log "Configuring $HOME/.zshenv..."
        
        cat > "$HOME/.zshenv" << EOF
# Minimal stub for Zsh to load configs from $XDG_CONFIG_HOME/zsh
export ZDOTDIR="$ZDOTDIR"
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
EOF
    fi





# # Config directory symlinks
#     declare -A ZSH_CONFIGS=(
#         ["$HOME/dotfiles/config/zsh/.zshenv"]="$HOME/.config/zsh/.zshenv"
#         ["$HOME/dotfiles/config/zsh/.zprofile"]="$HOME/.config/zsh/.zprofile"
#         ["$HOME/dotfiles/config/zsh/.zshrc"]="$HOME/.config/zsh/.zshrc"
#     )

    # for src in "${!ZSH_CONFIGS[@]}"; do
    #     local dest=${ZSH_CONFIGS[$src]}
    #     # local full_src="$DOTFILES/config/$src"
    #     # local full_dest="$CONFIG_DIR/$dest"
        
    #     log "Linking $src to $dest"
    #     link_config "$src" "$dest"
    # done

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

    source "$DOTFILES/scripts/macos-defaults.sh"
    
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
    find "$DOTFILES" -name ".DS_Store" -delete
}

# Main installation
main() {
    log "Starting dotfiles installation..."
    
    clean_ds_store
    setup_zsh
    # backup_existing
    # create_symlinks
    source "$DOTFILES/scripts/symlinks.sh"
    setup_homebrew
    # setup_git
    # setup_macos
    
    log "Installation complete! Please restart your shell and Finder."
    log "Your old configurations have been backed up to ~/.dotfiles_backup if they existed."
}

main "$@"
