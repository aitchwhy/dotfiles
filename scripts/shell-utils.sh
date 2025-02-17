#!/bin/sh
# base-utils.sh - Core shell utilities for initial system setup
# Must work on a fresh macOS system with minimal dependencies

# Enforce POSIX
set -o posix

# Basic system detection without external dependencies
is_macos() {
    [ "$(uname -s)" = "Darwin" ]
}

is_apple_silicon() {
    [ "$(uname -m)" = "arm64" ]
}

# Core command existence check without relying on external commands
command_exists() {
    type "$1" >/dev/null 2>&1
}

# Safe path handling
get_script_dir() {
    # Handle symlinks
    SOURCE="${BASH_SOURCE[0]:-$0}"
    while [ -h "$SOURCE" ]; do
        DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
        SOURCE="$(readlink "$SOURCE")"
        [ "$SOURCE" != /* ] && SOURCE="$DIR/$SOURCE"
    done
    cd -P "$( dirname "$SOURCE" )" && pwd
}

# Basic path setup without external dependencies
setup_base_paths() {
    # Define core paths
    DOTFILES_DIR="$(get_script_dir)"
    export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
    export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
    export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
    export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
    
    # Create necessary directories
    for dir in "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"; do
        [ ! -d "$dir" ] && mkdir -p "$dir"
    done
}

# Safe file operations
ensure_dir() {
    [ -d "$1" ] || mkdir -p "$1"
}

safe_source() {
    [ -f "$1" ] && . "$1"
}

# Basic alias management
alias_if_exists() {
    [ $# -lt 2 ] && return 1
    if command_exists "${2%% *}"; then
        alias "$1"="$2"
        return 0
    fi
    return 1
}

# Environment setup helpers
prepend_path() {
    [ -d "$1" ] || return 1
    case ":$PATH:" in
        *":$1:"*) return 1 ;;
        *) export PATH="$1:$PATH" ;;
    esac
}

append_path() {
    [ -d "$1" ] || return 1
    case ":$PATH:" in
        *":$1:"*) return 1 ;;
        *) export PATH="$PATH:$1" ;;
    esac
}

# Initialize base environment
init_base_env() {
    setup_base_paths
    
    # Essential paths for macOS
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

# Export functions for use in other scripts
export -f is_macos
export -f is_apple_silicon
export -f command_exists
export -f ensure_dir
export -f safe_source
export -f alias_if_exists
export -f prepend_path
export -f append_path