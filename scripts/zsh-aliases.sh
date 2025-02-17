#!/bin/zsh
# early-aliases.zsh - Early-stage ZSH alias setup
# Must work before ZDOTDIR is fully configured

# Source base utilities
. "${0:A:h}/base-utils.sh" || return 1

# Initialize core environment
init_base_env

# Early CLI tool aliases - minimal set for initial setup
setup_early_cli_aliases() {
    local -A early_replacements=(
        [vi]="nvim"
        [vim]="nvim"
        [cat]="bat --paging=never"
        [ls]="eza --icons --group-directories-first"
        [ll]="eza -l --icons --group-directories-first"
        [la]="eza -la --icons --group-directories-first"
    )

    for cmd in "${(@k)early_replacements}"; do
        alias_if_exists "$cmd" "${early_replacements[$cmd]}"
    done
}

# Setup minimal required directories
setup_early_dirs() {
    ensure_dir "${XDG_CONFIG_HOME}/zsh"
    ensure_dir "${XDG_DATA_HOME}/zsh"
    ensure_dir "${XDG_CACHE_HOME}/zsh"
}

# Early stage setup
setup_early_env() {
    # Set ZDOTDIR if not already set
    export ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"
    
    # Create required directories
    setup_early_dirs
    
    # Setup basic aliases
    setup_early_cli_aliases
}

# Initialize early environment
setup_early_env