#!/usr/bin/env bash
# Dotfiles management script - handles setup, update, and sync
set -euo pipefail

# Source utilities
source "$(dirname "${BASH_SOURCE[0]}")/shell-utils.sh"

# Script options
FORCE=false
DRY_RUN=false
INSTALL_BREW=true
CONFIGURE_MACOS=true

# Process arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --force) FORCE=true ;;
        --dry-run) DRY_RUN=true ;;
        --no-brew) INSTALL_BREW=false ;;
        --no-macos) CONFIGURE_MACOS=false ;;
        --help)
            echo "Usage: $0 [--force] [--dry-run] [--no-brew] [--no-macos]"
            exit 0 ;;
        *) error "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

# Core symlink functionality
create_symlink() {
    local src="$1"
    local dest="$2"
    local dest_dir="$(dirname "$dest")"

    [[ ! -e "$src" ]] && { warn "Source missing: $src"; return 1; }
    ensure_dir "$dest_dir"

    if [[ -L "$dest" ]]; then
        [[ "$(readlink "$dest")" == "$src" ]] && { success "Already linked: $dest → $src"; return 0; }
    fi

    if [[ -e "$dest" ]]; then
        if [[ "$FORCE" != true ]]; then
            warn "File exists: $dest"
            read -p "Replace? [y/N] " -n 1 -r
            echo
            [[ ! $REPLY =~ ^[Yy]$ ]] && { warn "Skipping: $dest"; return 0; }
        fi
        backup_file "$dest"
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log "Would link: $dest → $src"
    else
        ln -sf "$src" "$dest"
        success "Linked: $dest → $src"
    fi
}

# Setup homebrew
setup_homebrew() {
    [[ "$INSTALL_BREW" != true ]] && return 0
    header "Setting up Homebrew"

    if ! command_exists brew; then
        if [[ "$DRY_RUN" == true ]]; then
            log "Would install Homebrew"
        else
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            if is_apple_silicon; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
        fi
    fi
}

# Setup zsh environment
setup_zsh() {
    header "Setting up Zsh environment"
    local zshenv="$HOME/.zshenv"

    if [[ -f "$zshenv" ]]; then
        [[ "$DRY_RUN" != true ]] && backup_file "$zshenv"
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log "Would create $zshenv"
    else
        cat >"$zshenv" <<EOL
# Minimal zsh configuration loader
export ZDOTDIR="\$HOME/.config/zsh"
[[ -f "\$ZDOTDIR/.zshenv" ]] && source "\$ZDOTDIR/.zshenv"
EOL
        success "Created $zshenv"
    fi
}

# Core setup functionality
setup_dotfiles() {
    # Shell config
    create_symlink "$DOTFILES/config/zsh" "$XDG_CONFIG_HOME/zsh"

    # Core tools
    create_symlink "$DOTFILES/config/git" "$XDG_CONFIG_HOME/git"
    create_symlink "$DOTFILES/config/nvim" "$XDG_CONFIG_HOME/nvim"
    create_symlink "$DOTFILES/config/starship/starship.toml" "$XDG_CONFIG_HOME/starship.toml"
    create_symlink "$DOTFILES/Brewfile" "$HOME/.Brewfile"

    # Terminal tools
    create_symlink "$DOTFILES/config/bat" "$XDG_CONFIG_HOME/bat"
    create_symlink "$DOTFILES/config/atuin" "$XDG_CONFIG_HOME/atuin"
    create_symlink "$DOTFILES/config/zellij" "$XDG_CONFIG_HOME/zellij"

    # macOS-specific
    if is_macos; then
        create_symlink "$DOTFILES/config/karabiner" "$XDG_CONFIG_HOME/karabiner"
        create_symlink "$DOTFILES/config/hammerspoon" "$HOME/.hammerspoon"

        local vscode_dir="$HOME/Library/Application Support/Code/User"
        create_symlink "$DOTFILES/config/vscode/settings.json" "$vscode_dir/settings.json"
        create_symlink "$DOTFILES/config/vscode/keybindings.json" "$vscode_dir/keybindings.json"
    fi
}

# Update functionality
update_dotfiles() {
    header "Updating dotfiles"
    cd "$DOTFILES"
    
    if [[ -n "$(git status --porcelain)" ]]; then
        git stash
        git pull origin main
        git stash pop || true
    else
        git pull origin main
    fi
}

# Cleanup functionality
cleanup_system() {
    header "Cleaning system"
    [[ "$DRY_RUN" == true ]] && { log "Would clean system"; return 0; }

    # Clean caches and old backups
    find "$XDG_CACHE_HOME" -type f -atime +30 -delete 2>/dev/null || true
    find "$HOME/.dotfiles_backup" -maxdepth 1 -type d -mtime +30 -exec rm -rf {} + 2>/dev/null || true
}

# Main execution
main() {
    init_core_env
    header "Starting dotfiles management"

    setup_homebrew
    setup_zsh
    setup_dotfiles
    update_dotfiles
    cleanup_system

    if [[ "$DRY_RUN" == true ]]; then
        success "Dry run completed"
    else
        success "Setup completed"
        [[ -d "$BACKUP_DIR" ]] && log "Backups stored in: $BACKUP_DIR"
    fi
}

main "$@"