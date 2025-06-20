#!/usr/bin/env bash

# ============================================================================
# Config Symlink Setup Script
# ============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { printf "${BLUE}[INFO]${NC} %s\n" "$*"; }
log_success() { printf "${GREEN}[✓]${NC} %s\n" "$*"; }
log_warn() { printf "${YELLOW}[!]${NC} %s\n" "$*" >&2; }
log_error() { printf "${RED}[✗]${NC} %s\n" "$*" >&2; }

# ============================================================================
# CONFIGURATION
# ============================================================================

# Base directories
DOTFILES_DIR="${DOTFILES:-$HOME/dotfiles}"
DOTFILES_CONFIG="$DOTFILES_DIR/.config"
HOME_CONFIG="$HOME/.config"

# List of config directories to symlink
# Add or remove items from this list as needed
CONFIG_DIRS=(
	"zsh"
	"nvim"
	"starship"
	"git"
	"lazygit"
	"atuin"
	"yazi"
	"zellij"
	"bat"
	"delta"
	"just"
	"npm"
	"gh"
	"htop"
	"direnv"
	"fd"
	"ripgrep"
)

# Optional: Additional individual files to symlink (if any)
CONFIG_FILES=(
	# Example: "ripgrep/ripgreprc"
)

# ============================================================================
# FUNCTIONS
# ============================================================================

# Check if a path is a symlink pointing to our dotfiles
is_our_symlink() {
	local path="$1"
	if [[ -L "$path" ]]; then
		local target=$(readlink "$path")
		[[ "$target" == "$DOTFILES_CONFIG"* ]]
	else
		return 1
	fi
}

# Backup existing config
backup_existing() {
	local path="$1"
	local backup_dir="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

	if [[ -e "$path" ]] && ! is_our_symlink "$path"; then
		mkdir -p "$backup_dir"
		local rel_path="${path#$HOME_CONFIG/}"
		local backup_path="$backup_dir/$rel_path"
		mkdir -p "$(dirname "$backup_path")"

		log_warn "Backing up existing $rel_path to $backup_path"
		mv "$path" "$backup_path"
		return 0
	fi
	return 1
}

# Create symlink with proper checks
create_symlink() {
	local src="$1"
	local dst="$2"
	local name="${dst#$HOME_CONFIG/}"

	# Check if source exists
	if [[ ! -e "$src" ]]; then
		log_warn "Source not found: $name (skipping)"
		return 1
	fi

	# Check if destination already exists
	if [[ -e "$dst" ]]; then
		if is_our_symlink "$dst"; then
			log_info "Already linked: $name"
			return 0
		else
			backup_existing "$dst"
		fi
	fi

	# Create parent directory if needed
	mkdir -p "$(dirname "$dst")"

	# Create the symlink
	if ln -sf "$src" "$dst"; then
		log_success "Linked: $name"
		return 0
	else
		log_error "Failed to link: $name"
		return 1
	fi
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

main() {
	log_info "Setting up config symlinks from $DOTFILES_CONFIG"

	# Ensure ~/.config exists and is a directory
	if [[ -L "$HOME_CONFIG" ]]; then
		log_error "~/.config is a symlink! This needs to be a real directory."
		log_info "Run: rm ~/.config && mkdir ~/.config"
		exit 1
	fi

	if [[ ! -d "$HOME_CONFIG" ]]; then
		log_info "Creating ~/.config directory"
		mkdir -p "$HOME_CONFIG"
	fi

	# Check if dotfiles config exists
	if [[ ! -d "$DOTFILES_CONFIG" ]]; then
		log_error "Dotfiles config not found at: $DOTFILES_CONFIG"
		exit 1
	fi

	# Process directories
	log_info "Linking config directories..."
	local success_count=0
	local skip_count=0
	local fail_count=0

	for dir in "${CONFIG_DIRS[@]}"; do
		src="$DOTFILES_CONFIG/$dir"
		dst="$HOME_CONFIG/$dir"

		if create_symlink "$src" "$dst"; then
			((success_count++))
		elif [[ -e "$src" ]]; then
			((fail_count++))
		else
			((skip_count++))
		fi
	done

	# Process individual files (if any)
	if [[ ${#CONFIG_FILES[@]} -gt 0 ]]; then
		log_info "Linking config files..."
		for file in "${CONFIG_FILES[@]}"; do
			src="$DOTFILES_CONFIG/$file"
			dst="$HOME_CONFIG/$file"

			if create_symlink "$src" "$dst"; then
				((success_count++))
			elif [[ -e "$src" ]]; then
				((fail_count++))
			else
				((skip_count++))
			fi
		done
	fi

	# Summary
	echo
	log_info "Summary:"
	log_success "Linked: $success_count"
	[[ $skip_count -gt 0 ]] && log_warn "Skipped: $skip_count (not found in dotfiles)"
	[[ $fail_count -gt 0 ]] && log_error "Failed: $fail_count"

	# Special case: Ensure ZDOTDIR is properly set
	if [[ -L "$HOME_CONFIG/zsh" ]]; then
		echo
		log_info "zsh config is linked. Ensure ZDOTDIR is set in ~/.zshenv:"
		echo "    export ZDOTDIR=\"\$HOME/.config/zsh\""
	fi
}

# ============================================================================
# ADDITIONAL UTILITIES
# ============================================================================

# Show current symlink status
status() {
	log_info "Current config symlinks:"
	echo

	for dir in "${CONFIG_DIRS[@]}"; do
		dst="$HOME_CONFIG/$dir"
		if [[ -L "$dst" ]]; then
			target=$(readlink "$dst")
			if [[ "$target" == "$DOTFILES_CONFIG"* ]]; then
				printf "${GREEN}✓${NC} %-20s -> %s\n" "$dir" "$target"
			else
				printf "${YELLOW}?${NC} %-20s -> %s\n" "$dir" "$target"
			fi
		elif [[ -e "$dst" ]]; then
			printf "${RED}✗${NC} %-20s (exists but not symlinked)\n" "$dir"
		else
			printf "  %-20s (not found)\n" "$dir"
		fi
	done
}

# Remove all our symlinks
unlink_all() {
	log_warn "Removing all config symlinks..."

	for dir in "${CONFIG_DIRS[@]}"; do
		dst="$HOME_CONFIG/$dir"
		if is_our_symlink "$dst"; then
			rm "$dst"
			log_success "Removed: $dir"
		fi
	done

	for file in "${CONFIG_FILES[@]}"; do
		dst="$HOME_CONFIG/$file"
		if is_our_symlink "$dst"; then
			rm "$dst"
			log_success "Removed: $file"
		fi
	done
}

# ============================================================================
# COMMAND HANDLING
# ============================================================================

case "${1:-setup}" in
setup)
	main
	;;
status)
	status
	;;
unlink)
	unlink_all
	;;
help | --help | -h)
	cat <<EOF
Config Symlink Manager

Usage: $0 [command]

Commands:
    setup    Create symlinks (default)
    status   Show current symlink status
    unlink   Remove all symlinks
    help     Show this help

Configuration:
    Edit CONFIG_DIRS array in this script to manage which configs to symlink.
    
Current directories managed:
$(printf '    - %s\n' "${CONFIG_DIRS[@]}")
EOF
	;;
*)
	log_error "Unknown command: $1"
	echo "Run '$0 help' for usage"
	exit 1
	;;
esac
