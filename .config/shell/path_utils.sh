#!/bin/bash
# Works in bash 3.2+ and zsh

# Load paths from config
load_paths() {
    paths=()
    while IFS= read -r dir; do
        [[ -n "$dir" && ! "$dir" =~ ^# ]] && paths+=("${dir/#\~/$HOME}")
    done < "$HOME/.config/shell/paths.conf"
}

# Build unique PATH
build_path() {
    local -A seen
    local new_path=""
    
    # Add from config first
    for dir in "${paths[@]}"; do
        [[ -d "$dir" && -z "${seen[$dir]}" ]] && {
            seen[$dir]=1
            new_path="${new_path:+$new_path:}$dir"
        }
    done
    
    # Preserve existing PATH entries
    local IFS=:
    for dir in $PATH; do
        [[ -d "$dir" && -z "${seen[$dir]}" ]] && {
            seen[$dir]=1
            new_path="${new_path:+$new_path:}$dir"
        }
    done
    
    PATH="$new_path"
}

# Print current PATH
path_print() {
    local IFS=:
    local i=1
    for dir in $PATH; do
        printf "%2d. %s\n" $((i++)) "$dir"
    done
}

# Initialize
load_paths
build_path
export PATH