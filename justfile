# Root justfile for dotfiles
# Usage: just [command]
# Version: 1.40.0

# Set shell to zsh for all recipes
set shell := ["zsh", "-cu"]

# Enable colorful output
set dotenv-load
set positional-arguments
set fallback

# Import all tool-specific justfiles recursively
import? "./*/justfile"
import? "./config/*/justfile"

# Default recipe - list all available commands with groups
default:
    @echo "=== Dotfiles Command Center ==="
    @echo "Use 'just COMMAND' or 'just TOOL COMMAND' to run commands"
    @echo "Use 'just choose' for fuzzy command selection"
    @echo ""
    @{{just_executable()}} --list --unsorted | tail -n +3 | sort

# Fuzzy choose and run a command
choose:
    @{{just_executable()}} $({{just_executable()}} --list --unsorted | tail -n +3 | sort | fzf --height=40% --reverse --border | awk '{print $1}')

# -----------------------------------------------------------
# Core system commands
# -----------------------------------------------------------

# Show dotfiles status and info
status:
    @echo "=== Dotfiles Status ==="
    @echo "Repository: $(pwd)"
    @echo "Configuration: $HOME/.config"
    @echo "Last update: $(stat -f '%Sm' VERSION.md)"
    @git -C "$(pwd)" status -s

# Update dotfiles repository
update:
    @echo "=== Updating Dotfiles ==="
    @git pull
    @./scripts/setup.sh --update
    @echo "Updating VERSION.md with current timestamp..."
    @sed -i '' "s/Date: .*/Date: $(date +'%Y-%m-%d')/" VERSION.md

# Run setup script with default options
setup:
    @echo "=== Setting Up Dotfiles ==="
    @./scripts/setup.sh

# Run setup script in dry-run mode
dry-run:
    @echo "=== Dry Run Setup ==="
    @./scripts/setup.sh --dry-run

# -----------------------------------------------------------
# Homebrew management
# -----------------------------------------------------------

# Install recommended packages from core Brewfile
brew-install-core:
    @echo "=== Installing Core Packages ==="
    @brew bundle install --file=Brewfile.core

# Install all packages including optional ones
brew-install-full:
    @echo "=== Installing All Packages ==="
    @brew bundle install --file=Brewfile.full

# Update all Homebrew packages
brew-update:
    @echo "=== Updating Homebrew Packages ==="
    @brew update
    @brew upgrade
    @brew cleanup

# Create/update Brewfile from currently installed packages
brew-dump:
    @echo "=== Creating Brewfile from Installed Packages ==="
    @brew bundle dump --force --describe

# Check for outdated packages
brew-outdated:
    @echo "=== Checking for Outdated Packages ==="
    @brew outdated

# -----------------------------------------------------------
# Backup and restore
# -----------------------------------------------------------

# Create backup of current config
backup:
    @echo "=== Creating Backup ==="
    @mkdir -p "$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
    @cp -R "$HOME/.config" "$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)/"
    @echo "Backup created at $HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# List all backups
backups:
    @echo "=== Available Backups ==="
    @ls -lh "$HOME/.dotfiles_backup" | tail -n +2

# Restore from backup (interactive)
restore:
    @echo "=== Restore from Backup ==="
    @backup_dir=$(ls -1 "$HOME/.dotfiles_backup" | fzf --height=40% --reverse --border --prompt="Select backup to restore: ")
    @if [ -n "$backup_dir" ]; then \
        echo "Restoring from $HOME/.dotfiles_backup/$backup_dir"; \
        rsync -av --progress "$HOME/.dotfiles_backup/$backup_dir/.config/" "$HOME/.config/"; \
        echo "Restore complete"; \
    else \
        echo "No backup selected"; \
    fi

# -----------------------------------------------------------
# System management
# -----------------------------------------------------------

# Check for missing dependencies
check-deps:
    @echo "=== Checking Dependencies ==="
    @which git >/dev/null || echo "Missing: git"
    @which zsh >/dev/null || echo "Missing: zsh"
    @which brew >/dev/null || echo "Missing: brew"
    @which nvim >/dev/null || echo "Missing: nvim"
    @which starship >/dev/null || echo "Missing: starship"
    @which yazi >/dev/null || echo "Missing: yazi"
    @which just >/dev/null || echo "Missing: just"

# List all changed files since last commit
changed:
    @git status -s

# Reload shell configuration
reload:
    @exec zsh

# Show system information
sysinfo:
    @echo "=== System Information ==="
    @echo "OS: $(uname -s) $(uname -r)"
    @echo "Architecture: $(uname -m)"
    @echo "Hostname: $(hostname)"
    @echo "User: $(whoami)"
    @echo "Shell: $SHELL"
    @echo "Terminal: $TERM"
    @echo "Directory: $(pwd)"
    @echo "Date: $(date)"

# -----------------------------------------------------------
# Documentation
# -----------------------------------------------------------

# View main README
readme:
    @glow README.md

# View PRD (Product Requirements Document)
prd:
    @glow PRD.md

# View version information
version:
    @glow VERSION.md

# View specific tool documentation
docs tool:
    @if [ -f "config/{{tool}}/README.md" ]; then \
        glow "config/{{tool}}/README.md"; \
    else \
        echo "No documentation found for {{tool}}"; \
    fi

# -----------------------------------------------------------
# Git operations
# -----------------------------------------------------------

# Show git status
git-status:
    @git status

# Commit all changes
git-commit message:
    @git add -A
    @git commit -m "{{message}}"

# Push changes to remote
git-push:
    @git push

# Pull changes from remote
git-pull:
    @git pull

# Show git log
git-log:
    @git log --oneline -n 10