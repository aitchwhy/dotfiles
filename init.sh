#!/usr/bin/env zsh
# ~/dotfiles/init.sh - Main initialization script

# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Core paths
DOTFILES="${HOME}/dotfiles"
ZDOTDIR="${DOTFILES}/home/zsh"
CACHE_DIR="${XDG_CACHE_HOME}/dotfiles"

# Create necessary directories
mkdir -p "${XDG_CONFIG_HOME}" "${XDG_CACHE_HOME}" "${XDG_DATA_HOME}" "${XDG_STATE_HOME}"
mkdir -p "${CACHE_DIR}"/{backups,zsh}
mkdir -p "${XDG_DATA_HOME}/zsh"

# Utility functions
quiet() { "$@" &>/dev/null; }
log() { echo "➜ $*" >&2; }
error() { echo "✘ $*" >&2; }
success() { echo "✓ $*" >&2; }
has_command() { command -v "$1" >/dev/null; }

# Create symlinks with backup
link() {
    local src="$1" dst="$2"
    local backup_dir="${CACHE_DIR}/backups/$(date +%Y%m%d_%H%M%S)"
    
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        mkdir -p "$backup_dir"
        mv "$dst" "${backup_dir}/$(basename "$dst")"
        log "Backed up existing $(basename "$dst")"
    fi
    
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    success "Linked $(basename "$src")"
}

# Setup symlinks
setup_zsh_symlinks() {
    # Core ZSH files
    link "${ZDOTDIR}/zshrc" "${HOME}/.zshrc"
    link "${ZDOTDIR}/zshenv" "${HOME}/.zshenv"
    link "${ZDOTDIR}/zprofile" "${HOME}/.zprofile"

    # Ensure XDG config directories exist
    mkdir -p "${XDG_CONFIG_HOME}/starship"
    
    # Link starship config if it exists
    if [[ -f "${DOTFILES}/config/starship.toml" ]]; then
        link "${DOTFILES}/config/starship.toml" "${XDG_CONFIG_HOME}/starship.toml"
    fi
}

# Initialize shell environment
shell_init() {
    [[ -o interactive ]] || return 0
    setup_zsh_symlinks
}

# Handle script execution vs. sourcing
if [[ "${ZSH_EVAL_CONTEXT:-}" == toplevel ]]; then
    shell_init
else
    shell_init
fi
