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

    # Link ZDOTDIR itself
    #link "${ZDOTDIR}" "${XDG_CONFIG_HOME}/zsh"
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



# # Configuration
# DOTFILES="${HOME}/dotfiles"
# CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
# CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"

# # Utility functions
# quiet() { "$@" &>/dev/null; }
# log() { echo "➜ $*" >&2; }
# error() { echo "✘ $*" >&2; }
# success() { echo "✓ $*" >&2; }

# # Initialize shell environment
# shell_init() {
#     # Only run in interactive shells
#     [[ -o interactive ]] || return 0

#     # Initialize Homebrew environment silently
#     if [[ -f "/opt/homebrew/bin/brew" ]]; then
#         quiet eval "$(/opt/homebrew/bin/brew shellenv)"
#     fi

#     # Setup ZSH completion system silently
#     if [[ ! -d "${CACHE_DIR}/zsh" ]]; then
#         mkdir -p "${CACHE_DIR}/zsh"
#     fi
#     autoload -Uz compinit
#     quiet compinit -d "${CACHE_DIR}/zsh/zcompdump"

#     # Source all ZSH configurations
#     for config in "${DOTFILES}/home/zsh"/*.zsh; do
#         [[ -f "$config" ]] && quiet source "$config"
#     done

#     # Load any additional tool configurations
#     [[ -f "${DOTFILES}/home/zprofile" ]] && quiet source "${DOTFILES}/home/zprofile"
# }

# # Create symlinks with backup
# link() {
#     local src="$1" dst="$2"
#     local backup_dir="${CACHE_DIR}/backups/$(date +%Y%m%d_%H%M%S)"
    
#     if [[ -e "$dst" && ! -L "$dst" ]]; then
#         mkdir -p "$backup_dir"
#         mv "$dst" "${backup_dir}/$(basename "$dst")"
#         log "Backed up existing $(basename "$dst")"
#     fi
    
#     mkdir -p "$(dirname "$dst")"
#     ln -sf "$src" "$dst"
#     success "Linked $(basename "$src")"
# }

# # Update dotfiles
# update_dotfiles() {
#     log "Updating dotfiles..."
    
#     # Core ZSH configurations
#     link "${DOTFILES}/home/zsh/zshrc" "${HOME}/.zshrc"
#     link "${DOTFILES}/home/zsh/zprofile" "${HOME}/.zprofile"
#     link "${DOTFILES}/home/zsh/zshenv" "${HOME}/.zshenv"
    
#     # Config directory links
#     local configs=(
#         "nvim"
#         "starship.toml"
#         "git/gitconfig"
#         "git/gitignore"
#         "hammerspoon/init.lua"
#         "karabiner/karabiner.json"
#         "ghostty/config"
#         "yazi"
#         "zed"
#         "zellij/config.kdl"
#         "atuin/config.toml"
#     )
    
#     for config in "${configs[@]}"; do
#         if [[ -e "${DOTFILES}/home/config/$config" ]]; then
#             link "${DOTFILES}/home/config/$config" "${CONFIG}/$config"
#         fi
#     done
    
#     success "Dotfiles updated"
# }

# # Update packages
# update_packages() {
#     log "Updating packages..."
    
#     # Install/Update Homebrew if needed
#     if ! command -v brew >/dev/null; then
#         error "Homebrew not found. Installing..."
#         /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#         eval "$(/opt/homebrew/bin/brew shellenv)"
#     fi
    
#     # Update Homebrew and packages
#     if [[ -f "${DOTFILES}/home/Brewfile" ]]; then
#         brew update
#         brew bundle --file="${DOTFILES}/home/Brewfile"
#         brew cleanup
#         success "Packages updated"
#     else
#         error "Brewfile not found at ${DOTFILES}/home/Brewfile"
#         return 1
#     fi
# }

# # Perform clean reinstall
# zap_reinstall() {
#     log "Performing clean reinstall..."
    
#     if command -v brew >/dev/null; then
#         log "Removing all Homebrew packages..."
#         brew list --formula | xargs brew uninstall --force
#         brew list --cask | xargs brew uninstall --force --zap
#     fi
    
#     # Clean caches
#     rm -rf "${CACHE_DIR}"/*
    
#     update_packages
#     update_dotfiles
    
#     success "Clean reinstall complete"
# }

# # Sync dotfiles (useful for multiple machines)
# sync_dotfiles() {
#     log "Syncing dotfiles..."
    
#     # Ensure git is initialized
#     if [[ ! -d "${DOTFILES}/.git" ]]; then
#         error "Git repository not initialized in ${DOTFILES}"
#         return 1
#     fi
    
#     # Sync
#     (cd "${DOTFILES}" && {
#         git pull origin $(git branch --show-current)
#         git add .
#         git commit -m "Auto-sync: $(date)"
#         git push origin $(git branch --show-current)
#     })
    
#     success "Dotfiles synced"
# }

# # Export current Brew packages
# export_packages() {
#     log "Exporting current packages..."
    
#     if command -v brew >/dev/null; then
#         brew bundle dump --force --file="${DOTFILES}/home/Brewfile"
#         success "Packages exported to ${DOTFILES}/home/Brewfile"
#     else
#         error "Homebrew not found"
#         return 1
#     fi
# }

# # Main command handler
# main() {
#     # Create necessary directories
#     mkdir -p "${CACHE_DIR}"/{backups,zsh}
    
#     case "${1:-help}" in
#         init)
#             shell_init
#             ;;
#         update)
#             update_dotfiles
#             update_packages
#             ;;
#         zap)
#             zap_reinstall
#             ;;
#         sync)
#             sync_dotfiles
#             ;;
#         export)
#             export_packages
#             ;;
#         help)
#             echo "Usage: $0 <command>"
#             echo "Commands:"
#             echo "  init    - Initialize shell environment"
#             echo "  update  - Update dotfiles and packages"
#             echo "  zap     - Remove everything and reinstall"
#             echo "  sync    - Sync dotfiles with remote repository"
#             echo "  export  - Export current Homebrew packages"
#             echo "  help    - Show this help message"
#             ;;
#         *)
#             error "Unknown command: $1"
#             echo "Run '$0 help' for usage information"
#             return 1
#             ;;
#     esac
# }

# # Handle script execution vs. sourcing
# if [[ "${ZSH_EVAL_CONTEXT:-}" == toplevel ]]; then
#     # Script is being run
#     main "$@"
# else
#     # Script is being sourced
#     shell_init
# fi


