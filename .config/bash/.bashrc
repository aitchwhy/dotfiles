#!/usr/bin/env bash

# ============================================================================
# BASH CONFIGURATION
# ============================================================================

# ============================================================================
# ENVIRONMENT SETUP
# ============================================================================

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"


# # Load path utilities
# [[ -f "$HOME/.config/shell/path_utils.sh" ]] && source "$HOME/.config/shell/path_utils.sh"

# . "$HOME/.atuin/bin/env"
# # [[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
# eval "$(atuin init bash)"

# # load all completions
# if [ -d ~/.bash_completion.d ]; then
#     for f in ~/.bash_completion.d/*.sh; do
#         [ -r "$f" ] && . "$f"
#     done
# fi

# [ -f ~/.fzf.bash ] && source ~/.fzf.bash

# # <ant-setup>
# # This was generated by ant-setup, feel free to remove it
# eval "\$(direnv hook bash)"
# # </ant-setup>

# if [ -n "$IN_NIX_SHELL" ]; then
#     # We're in a nix-shell or nix develop
#     source "${cf:-$HOME/dotfiles/config}/nix/.bashrc.nix-shell"
# fi


# # Volta (Node.js)
# export VOLTA_HOME="$HOME/.volta"
# export PATH="$VOLTA_HOME/bin:$PATH"
#
# # NPM Global
# export PATH="$HOME/.npm-global/bin:$PATH"
#
# # Cargo (Rust)
# [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
#
# # GHCup (Haskell)
# [[ -f "$HOME/.ghcup/env" ]] && source "$HOME/.ghcup/env"
#
# # LM Studio
# export PATH="$PATH:$HOME/.lmstudio/bin"
#
# # Atuin (Shell History)
# [[ -f "$HOME/.atuin/bin/env" ]] && source "$HOME/.atuin/bin/env"
#
# # FZF
# if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
# 	PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
# fi
#
# # Direnv
eval "$(direnv hook bash)"

eval "$(fzf --bash)"

# # # Custom path utilities
# # [[ -f "$HOME/.config/shell/path_utils.sh" ]] && source "$HOME/.config/shell/path_utils.sh"
# #
# # ============================================================================
# # COLORS AND LOGGING
# # ============================================================================
#
# export BLUE='\033[0;34m'
# export GREEN='\033[0;32m'
# export YELLOW='\033[1;33m'
# export RED='\033[0;31m'
# export RESET='\033[0m'
#
# log_info() { printf "${BLUE}[INFO]${RESET} %s\n" "$*"; }
# log_success() { printf "${GREEN}[SUCCESS]${RESET} %s\n" "$*"; }
# log_warn() { printf "${YELLOW}[WARNING]${RESET} %s\n" "$*" >&2; }
# log_error() { printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2; }
#
# # ============================================================================
# # SYSTEM DETECTION
# # ============================================================================
#
# has_command() { command -v "$1" &>/dev/null; }
# is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }
# is_linux() { [[ "$(uname -s)" == "Linux" ]]; }
#
# ============================================================================
# ALIASES
# ============================================================================
#
# # Task Master
# alias tm='task-master'
# alias taskmaster='task-master'
# alias j="just"
# alias .j='just --justfile ~/dotfiles/justfile --working-directory .'
#
# # Docker shortcuts
# alias dps='docker ps'
# alias dpsa='docker ps -a'
# alias dlog='docker logs -f'
# alias dex='docker exec -it'
# alias drm='docker rm'
# alias drmi='docker rmi'
# alias dstop='docker stop'
# alias dstart='docker start'
#
# # Git shortcuts
# alias g='git'
# alias gs='git status'
# alias ga='git add'
# alias gc='git commit'
# alias gp='git push'
# alias gl='git log --oneline --graph --decorate'
# alias gd='git diff'
# alias gco='git checkout'
#
# # System shortcuts
# alias ll='ls -la'
# alias la='ls -A'
# alias l='ls -CF'
# alias ..='cd ..'
# alias ...='cd ../..'
# alias ....='cd ../../..'
#
# ============================================================================
# SYSTEM UTILITIES
# ============================================================================

# ============================================================================
# PATH MANAGEMENT
# ============================================================================
# ============================================================================
# BREW UTILITIES
# ============================================================================
# ============================================================================
# COMPLETION AND PROMPT
# ============================================================================
#
# # Enable bash completion
# [[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"
#
# # Simple prompt with git branch
# parse_git_branch() {
#   git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
# }
#
# PS1='\[\e[0;32m\]\u@\h\[\e[0m\]:\[\e[0;34m\]\w\[\e[0;33m\]$(parse_git_branch)\[\e[0m\]\$ '
#
# ============================================================================
# LOCAL OVERRIDES
# ============================================================================

# # Source local bashrc if it exists
# [[ -f "$HOME/.bashrc.local" ]] && source "$HOME/.bashrc.local"
# . "$HOME/.cargo/env"
#
# # uv
# export PATH="/Users/hank/.local/share/../bin:$PATH"

alias 

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/hank/.lmstudio/bin"
# End of LM Studio CLI section

