#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${BLUE}INFO:${NC} $1"; }
log_success() { echo -e "${GREEN}SUCCESS:${NC} $1"; }
log_error() { echo -e "${RED}ERROR:${NC} $1" >&2; }

# Helper to create backup with timestamp
backup_if_exists() {
    local file="$1"
    if [[ -e "$file" && ! -L "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d%H%M%S)"
        log_info "Backing up $file to $backup"
        mv "$file" "$backup"
    elif [[ -L "$file" ]]; then
        log_info "Removing existing symlink $file"
        rm "$file"
    fi
}

# Create directory if it doesn't exist
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        log_info "Creating directory $dir"
        mkdir -p "$dir"
    fi
}

# Setup XDG directories
setup_xdg() {
    ensure_dir "${HOME}/.config"
    ensure_dir "${HOME}/.cache"
    ensure_dir "${HOME}/.local/share"
    ensure_dir "${HOME}/.local/state"
}
setup_zsh() {
    local zsh_config="${HOME}/.config/zsh"
    local dotfiles_zsh="${HOME}/dotfiles/home/config/zsh"
    local state_dir="${HOME}/.local/state/zsh"
    local cache_dir="${HOME}/.cache/zsh"

    # Create necessary directories
    ensure_dir "$zsh_config"
    ensure_dir "$state_dir"
    ensure_dir "$cache_dir"
    ensure_dir "${zsh_config}/completions.d"

    # Backup existing .zshenv in home directory
    backup_if_exists "${HOME}/.zshenv"

    # Create initial .zshenv to set ZDOTDIR
    cat > "${HOME}/.zshenv" << EOF
# Set XDG paths
export XDG_CONFIG_HOME="\${HOME}/.config"
export XDG_CACHE_HOME="\${HOME}/.cache"
export XDG_DATA_HOME="\${HOME}/.local/share"
export XDG_STATE_HOME="\${HOME}/.local/state"

# Set ZSH directory
export ZDOTDIR="\${XDG_CONFIG_HOME}/zsh"
EOF

    # Setup antidote
    local antidote_dir="${zsh_config}/.antidote"
    if [[ ! -d "$antidote_dir" ]]; then
        log_info "Installing antidote..."
        git clone --depth=1 https://github.com/mattmc3/antidote.git "$antidote_dir"
    fi

    # Symlink each file individually instead of the whole directory
    for file in "${dotfiles_zsh}"/*; do
        local fname=$(basename "$file")
        local target="${zsh_config}/${fname}"
        backup_if_exists "$target"
        log_info "Creating symlink for ${fname}"
        ln -sf "$file" "$target"
    done

    # Generate static plugin file
    if command -v antidote > /dev/null; then
        log_info "Generating static plugins file..."
        antidote bundle < "${dotfiles_zsh}/plugins.txt" > "${zsh_config}/.plugins.zsh"
    fi
}

main() {
    log_info "Starting dotfiles initialization..."
    
    setup_xdg
    setup_zsh

    log_success "Dotfiles initialization complete!"
}

main "$@"