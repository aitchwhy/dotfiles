#!/bin/sh
# Core shell utilities for dotfiles management
# Compatible with POSIX shell, zsh, and bash

# Core environment setup
setup_core_env() {
    DOTFILES="${DOTFILES:-$HOME/dotfiles}"
    XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
    XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
    XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
    XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
    ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"
    BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
    export DOTFILES XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME ZDOTDIR
}

# ANSI colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Logging functions
log() { echo -e "${BLUE}==>${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*" >&2; }
header() { echo -e "\n${BOLD}$*${NC}"; }

# System detection
is_macos() { [ "$(uname)" = "Darwin" ]; }
is_arm64() { [ "$(uname -m)" = "arm64" ]; }
is_apple_silicon() { is_macos && is_arm64; }

# Command and directory handling
command_exists() { command -v "$1" >/dev/null 2>&1; }
ensure_dir() { [ -d "$1" ] || mkdir -p "$1"; }

# File operations
backup_file() {
    local file="$1"
    if [ -e "$file" ]; then
        local backup="$file.backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$(dirname "$backup")"
        mv "$file" "$backup"
        success "Backed up: $file → $backup"
    fi
}

# Path management
prepend_path() {
    [ -d "$1" ] || return 1
    case ":$PATH:" in
        *":$1:"*) return 1 ;;
        *) export PATH="$1:$PATH" ;;
    esac
}

# XDG directory setup
setup_xdg_dirs() {
    for dir in \
        "$XDG_CONFIG_HOME" \
        "$XDG_CACHE_HOME" \
        "$XDG_DATA_HOME" \
        "$XDG_STATE_HOME" \
        "$ZDOTDIR"
    do
        ensure_dir "$dir"
    done
}

# Initialize core environment
init_core_env() {
    setup_core_env
    setup_xdg_dirs
    
    if is_macos; then
        for path in \
            "/opt/homebrew/bin" \
            "/opt/homebrew/sbin" \
            "/usr/local/bin" \
            "/usr/local/sbin" \
            "$HOME/.local/bin"
        do
            prepend_path "$path"
        done
    fi
}