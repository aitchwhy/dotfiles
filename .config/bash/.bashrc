#!/usr/bin/env bash

# ============================================================================
# BASH CONFIGURATION
# ============================================================================

# ============================================================================
# ENVIRONMENT SETUP
# ============================================================================

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Volta (Node.js)
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# NPM Global
export PATH="$HOME/.npm-global/bin:$PATH"

# Cargo (Rust)
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# GHCup (Haskell)
[[ -f "$HOME/.ghcup/env" ]] && source "$HOME/.ghcup/env"

# LM Studio
export PATH="$PATH:$HOME/.lmstudio/bin"

# Atuin (Shell History)
[[ -f "$HOME/.atuin/bin/env" ]] && source "$HOME/.atuin/bin/env"

# FZF
if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
	PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
fi
eval "$(fzf --bash)"

# Direnv
eval "$(direnv hook bash)"

# Custom path utilities
[[ -f "$HOME/.config/shell/path_utils.sh" ]] && source "$HOME/.config/shell/path_utils.sh"

# ============================================================================
# COLORS AND LOGGING
# ============================================================================

export BLUE='\033[0;34m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export RED='\033[0;31m'
export RESET='\033[0m'

log_info() { printf "${BLUE}[INFO]${RESET} %s\n" "$*"; }
log_success() { printf "${GREEN}[SUCCESS]${RESET} %s\n" "$*"; }
log_warn() { printf "${YELLOW}[WARNING]${RESET} %s\n" "$*" >&2; }
log_error() { printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2; }

# ============================================================================
# SYSTEM DETECTION
# ============================================================================

has_command() { command -v "$1" &>/dev/null; }
is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }
is_linux() { [[ "$(uname -s)" == "Linux" ]]; }

# ============================================================================
# ALIASES
# ============================================================================

# Task Master
alias tm='task-master'
alias taskmaster='task-master'

# Docker shortcuts
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dlog='docker logs -f'
alias dex='docker exec -it'
alias drm='docker rm'
alias drmi='docker rmi'
alias dstop='docker stop'
alias dstart='docker start'

# Git shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gco='git checkout'

# System shortcuts
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ============================================================================
# SYSTEM UTILITIES
# ============================================================================

# System utility command
sys() {
	case "$1" in
	env)
		shift
		echo "======== env vars =========="
		if [[ -z "$1" ]]; then
			printenv | sort | awk -F= '{ printf "%-30s %s\n", $1, $2 }'
		else
			printenv | sort | grep -i "$1" | awk -F= '{ printf "%-30s %s\n", $1, $2 }'
		fi
		echo "============================"
		;;

	hidden)
		local current=$(defaults read com.apple.finder AppleShowAllFiles)
		defaults write com.apple.finder AppleShowAllFiles $((1 - current))
		killall Finder
		echo "Finder hidden files: $((1 - current))"
		;;

	killport)
		local port="$2"
		[[ -z "$port" ]] && {
			echo "Usage: sys killport <port>"
			return 1
		}

		local pid=$(lsof -i ":$port" | awk 'NR!=1 {print $2}')
		[[ -z "$pid" ]] && {
			echo "No process found on port $port"
			return 1
		}

		echo "Killing process(es) on port $port: $pid"
		echo "$pid" | xargs kill -9
		echo "Process(es) killed"
		;;

	ports)
		sudo lsof -iTCP -sTCP:LISTEN -n -P
		;;

	disk)
		df -h
		;;

	cpu)
		top -l 1 | grep -E "^CPU"
		;;

	mem)
		vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages\s+([^:]+)[^\d]+(\d+)/ and printf("%-16s % 16.2f MB\n", "$1:", $2 * $size / 1048576);'
		;;

	path)
		echo "PATH components:"
		echo $PATH | tr ':' '\n' | nl | awk '{printf "  %2d: %s\n", $1, $2}'
		;;

	ip)
		echo "Public IP: $(curl -s https://ipinfo.io/ip)"
		echo "Local IP: $(ipconfig getifaddr en0)"
		;;

	help | *)
		echo "System utilities"
		echo ""
		echo "Usage: sys <command> [args]"
		echo ""
		echo "Commands:"
		echo "  env [pattern]     Display environment variables"
		echo "  hidden            Toggle hidden files in Finder"
		echo "  killport <port>   Kill process on port"
		echo "  ports             Show listening ports"
		echo "  disk              Check disk space"
		echo "  cpu               Show CPU usage"
		echo "  mem               Show memory usage"
		echo "  path              List PATH entries"
		echo "  ip                Show IP addresses"
		;;
	esac
}

# ============================================================================
# PATH MANAGEMENT
# ============================================================================

path_add() {
	local dir="$1"
	if [[ -d "$dir" ]] && [[ ":$PATH:" != *":$dir:"* ]]; then
		export PATH="$dir:$PATH"
		log_success "Added to PATH: $dir"
	fi
}

path_remove() {
	local dir="$1"
	if [[ ":$PATH:" == *":$dir:"* ]]; then
		export PATH=${PATH//:$dir:/:}
		export PATH=${PATH/#$dir:/}
		export PATH=${PATH/%:$dir/}
		log_success "Removed from PATH: $dir"
	fi
}

path_list() {
	echo $PATH | tr ':' '\n' | nl | awk '{printf "  %2d: %s\n", $1, $2}'
}

# ============================================================================
# DOCKER UTILITIES
# ============================================================================

# Docker container selector
d() {
	case "$1" in
	sh)
		local container=$(docker ps --format "table {{.Names}}\t{{.Image}}" | tail -n +2 | fzf | awk '{print $1}')
		[[ -n "$container" ]] && docker exec -it "$container" sh
		;;

	bash)
		local container=$(docker ps --format "table {{.Names}}\t{{.Image}}" | tail -n +2 | fzf | awk '{print $1}')
		[[ -n "$container" ]] && docker exec -it "$container" bash
		;;

	logs)
		local container=$(docker ps --format "table {{.Names}}\t{{.Image}}" | tail -n +2 | fzf | awk '{print $1}')
		[[ -n "$container" ]] && docker logs -f "$container"
		;;

	rm)
		local container=$(docker ps -a --format "table {{.Names}}\t{{.Image}}" | tail -n +2 | fzf | awk '{print $1}')
		[[ -n "$container" ]] && docker rm "$container"
		;;

	stop)
		local container=$(docker ps --format "table {{.Names}}\t{{.Image}}" | tail -n +2 | fzf | awk '{print $1}')
		[[ -n "$container" ]] && docker stop "$container"
		;;

	help | *)
		echo "Docker shortcuts"
		echo ""
		echo "Usage: d <command>"
		echo ""
		echo "Commands:"
		echo "  sh      Open sh in container"
		echo "  bash    Open bash in container"
		echo "  logs    Follow container logs"
		echo "  rm      Remove container"
		echo "  stop    Stop container"
		;;
	esac
}

# ============================================================================
# BREW UTILITIES
# ============================================================================

# Brew shortcuts
b() {
	case "$1" in
	up)
		brew update && brew upgrade && brew cleanup
		;;

	search)
		shift
		brew search "$@"
		;;

	info)
		shift
		brew info "$@"
		;;

	clean)
		brew cleanup --prune=all && brew autoremove
		;;

	leaves)
		brew leaves
		;;

	help | *)
		echo "Homebrew shortcuts"
		echo ""
		echo "Usage: b <command> [args]"
		echo ""
		echo "Commands:"
		echo "  up        Update and upgrade all"
		echo "  search    Search packages"
		echo "  info      Show package info"
		echo "  clean     Clean old versions"
		echo "  leaves    Show leaf packages"
		echo ""
		echo "For other commands, use 'brew' directly"
		;;
	esac
}

# ============================================================================
# FILE OPERATIONS
# ============================================================================

# Create directory and cd into it
mkcd() {
	mkdir -p "$1" && cd "$1"
}

# Create symbolic link with parent directory creation
slink() {
	[[ $# -lt 2 ]] && {
		echo "Usage: slink <src> <dst>"
		return 1
	}
	local src="$1" dst="$2"
	mkdir -p "$(dirname "$dst")"
	ln -nfs "$src" "$dst"
	log_success "Symlinked: $dst -> $src"
}

# ============================================================================
# FZF UTILITIES
# ============================================================================

# FZF with preview
f() {
	case "$1" in
	find)
		fd --type f --hidden --follow --exclude .git . "${2:-.}" |
			fzf --preview 'bat --style=numbers --color=always {}' --multi
		;;

	grep)
		shift
		rg --line-number --no-heading --color=always "${1:-.}" |
			fzf --ansi --delimiter : \
				--preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
				--preview-window 'right,60%,+{2}+3/3'
		;;

	cd)
		local dir=$(fd --type d --hidden --follow --exclude .git . "${2:-.}" |
			fzf --preview 'tree -C {} | head -200')
		[[ -n "$dir" ]] && cd "$dir"
		;;

	help | *)
		echo "FZF utilities"
		echo ""
		echo "Usage: f <command> [args]"
		echo ""
		echo "Commands:"
		echo "  find [dir]    Find files"
		echo "  grep [term]   Grep in files"
		echo "  cd [dir]      Change directory"
		;;
	esac
}

# ============================================================================
# DEVELOPMENT UTILITIES
# ============================================================================

# Quick git commit
qc() {
	git add -A && git commit -m "$*"
}

# Git status with changes
gst() {
	git status -s
	echo ""
	git diff --stat
}

# Update all development tools
update_all() {
	log_info "Updating Homebrew..."
	brew update && brew upgrade && brew cleanup

	if has_command rustup; then
		log_info "Updating Rust..."
		rustup update
	fi

	if has_command npm; then
		log_info "Updating npm packages..."
		npm update -g
	fi

	log_success "All tools updated"
}

# ============================================================================
# MACOS DEFAULTS
# ============================================================================

setup_macos() {
	log_info "Applying macOS preferences..."

	# Keyboard
	defaults write NSGlobalDomain KeyRepeat -int 2
	defaults write NSGlobalDomain InitialKeyRepeat -int 15
	defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

	# Finder
	defaults write NSGlobalDomain AppleShowAllExtensions -bool true
	defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
	defaults write com.apple.finder AppleShowAllFiles -bool true

	# Dock
	defaults write com.apple.dock autohide -bool true
	defaults write com.apple.dock autohide-delay -float 0

	killall Finder Dock
	log_success "macOS preferences applied"
}

# ============================================================================
# COMPLETION AND PROMPT
# ============================================================================

# Enable bash completion
[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"

# Simple prompt with git branch
parse_git_branch() {
	git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

PS1='\[\e[0;32m\]\u@\h\[\e[0m\]:\[\e[0;34m\]\w\[\e[0;33m\]$(parse_git_branch)\[\e[0m\]\$ '

# ============================================================================
# LOCAL OVERRIDES
# ============================================================================

# Source local bashrc if it exists
[[ -f "$HOME/.bashrc.local" ]] && source "$HOME/.bashrc.local"
. "$HOME/.cargo/env"
