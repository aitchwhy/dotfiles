#!/usr/bin/env zsh

# ========================================================================
# bootstrap.zsh - macOS dotfiles bootstrap script
# ========================================================================

set -euo pipefail

# ========================================================================
# Environment Configuration
# ========================================================================
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Source utilities
source "$DOTFILES/utils.zsh"

# ========================================================================
# System Requirements Check
# ========================================================================
check_requirements() {
    info "Checking system requirements..."

    # Check if running on macOS
    if ! is_macos; then
        error "This script is designed for macOS only."
        exit 1
    fi

    # Check if running on Apple Silicon
    if ! is_apple_silicon; then
        error "This script is designed for Apple Silicon Macs only."
        exit 1
    fi

    # Check for required commands
    local required_commands=(
        "git"
        "curl"
        "zsh"
    )

    for cmd in "${required_commands[@]}"; do
        if ! has_command "$cmd"; then
            error "Required command not found: $cmd"
            exit 1
        fi
    done

    success "System requirements met"
}

# ========================================================================
# Dotfiles Setup
# ========================================================================
setup_dotfiles() {
    info "Setting up dotfiles..."

    # Clone dotfiles repository if it doesn't exist
    if [[ ! -d "$DOTFILES" ]]; then
        info "Cloning dotfiles repository..."
        git clone https://github.com/yourusername/dotfiles.git "$DOTFILES"
    fi

    # Update dotfiles
    info "Updating dotfiles..."
    cd "$DOTFILES"
    git pull origin main

    # Run installation script
    info "Running installation script..."
    ./install.zsh

    success "Dotfiles setup complete"
}

# ========================================================================
# Main Function
# ========================================================================
main() {
    info "Starting dotfiles bootstrap for macOS..."

    # Check system requirements
    check_requirements

    # Setup dotfiles
    setup_dotfiles

    success "Bootstrap complete! 🎉"
    info "Please log out and log back in, or restart your computer for all changes to take effect."
    info "To finish setting up your shell, run: exec zsh"
}

# Run the script
main "$@"
