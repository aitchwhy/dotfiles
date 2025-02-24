#!/bin/zsh

# Default paths (can be overridden before sourcing)
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

# ################################################################################
# # PACKAGE MANAGEMENT
# # https://github.com/junegunn/fzf/wiki/examples#homebrew
# ################################################################################


# Homebrew utilities
function has_brew() {
    command -v brew >/dev/null 2>&1
}

function ensure_brew() {
    if ! has_brew; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add to PATH for current session if installed
        if is_arm64; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
}

function update_brew() {
    if has_brew; then
        log_info "Updating Homebrew..."
        brew update
        brew upgrade
        brew cleanup
    fi
}

# fix homebrew "zsh compinit: insecure directories"
function fix_brew_completion_insecure_dirs() {
	chmod -R go-w "$(brew --prefix)/share"
}


 # Clean .DS_Store files
function clean_ds_store() {
   log "Cleaning .DS_Store files..."
   find "$DOTFILES" -name ".DS_Store" -delete
 }


 # Logging functions
 log_info() {
     printf '%s[INFO]%s %s\n' "${BLUE}" "${RESET}" "$*"
 }

 log_success() {
     printf '%s[SUCCESS]%s %s\n' "${GREEN}" "${RESET}" "$*"
 }

 log_warning() {
     printf '%s[WARNING]%s %s\n' "${YELLOW}" "${RESET}" "$*" >&2
 }

 log_error() {
     printf '%s[ERROR]%s %s\n' "${RED}" "${RESET}" "$*" >&2
 }

 # Progress indicator
 show_progress() {
     printf '%s→%s %s...\n' "${BLUE}" "${RESET}" "$*"
 }


 ################################################################################
 # SYSTEM AND ENVIRONMENT DETECTION
 ################################################################################

 # OS detection
 is_macos() {
     [ "$(uname)" = "Darwin" ]
 }

 is_linux() {
     [ "$(uname)" = "Linux" ]
 }

 # Architecture detection
 is_arm64() {
     [ "$(uname -m)" = "arm64" ] || [ "$(uname -m)" = "aarch64" ]
 }


 chmod -R go-w "$(brew --prefix)/share"
