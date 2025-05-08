# Global justfile for common tasks
# Usage: j <recipe>

# Default recipe to show available recipes
default:
    @just --list

# ========================================================================
# System & Environment Management
# ========================================================================

# Update all package managers and tools
update:
    @echo "Updating system packages and tools..."
    brew update && brew upgrade && brew cleanup
    command -v volta >/dev/null && volta list || true
    command -v nix >/dev/null && nix-env -u || true

# Clean up system disk space
cleanup: cleanup-brew cleanup-nix cleanup-node
    @echo "System cleanup completed"

# Clean Homebrew cache and remove old versions
cleanup-brew:
    brew cleanup --prune=all
    brew autoremove

# Clean Nix store
cleanup-nix:
    command -v nix-collect-garbage >/dev/null && nix-collect-garbage -d || true

# Clean npm/node caches
cleanup-node:
    command -v npm >/dev/null && npm cache clean --force || true
    rm -rf ~/.npm/_cacache 2>/dev/null || true

# Show system information
info:
    @echo "System Information"
    @echo "=================="
    @echo "OS: $(uname -s) $(uname -r)"
    @echo "Architecture: $(uname -m)"
    command -v sw_vers >/dev/null && sw_vers || true
    @echo "\nBrew:"
    command -v brew >/dev/null && brew config | grep HOMEBREW || true
    @echo "\nShell: $SHELL ($(basename $SHELL))"

# ========================================================================
# dotfiles Management
# ========================================================================

# Update dotfiles repo
dotfiles-update:
    @cd ~/dotfiles && git pull

# Edit global justfile
edit-just:
    $EDITOR ~/dotfiles/config/just/global.justfile

# Fix platform Nix integration
nix-fix:
    @echo "Fixing Nix integration for the platform project..."
    @~/dotfiles/scripts/fix-platform-nix.sh ~/src/platform

# ========================================================================
# Git Helpers
# ========================================================================

# Create a new branch for a feature
git-feature NAME:
    git checkout -b "feature/{{ NAME }}"
    git push -u origin "feature/{{ NAME }}"

# Create a new branch for a bugfix
git-bugfix NAME:
    git checkout -b "bugfix/{{ NAME }}"
    git push -u origin "bugfix/{{ NAME }}"

# Show recent branches
git-recent:
    git for-each-ref --sort=-committerdate --count=10 --format='%(refname:short)' refs/heads/

# ========================================================================
# Platform Specific Commands
# ========================================================================

# Platform command
ant-platform:
    cd ~/src/platform && nix develop -c "ant-all-services"

# Anterior services
ant-platform-noggin: ant-platform
    cd ~/src/platform && nix develop --command zsh -c "./scripts/ant-all-services noggin"

ant-vibes-deploy-local app:
    cd ~/src/vibes/apps/{{ app }} && ./deploy-local.sh

ant-vibes-build:
    just ant-vibes-deploy-local flonotes
    just ant-vibes-deploy-local flopilot

# ant-dev:
#   cd ~/src/platform && nix develop .#npm -c

ant-noggin:
    cd ~/src/platform && source .env && npm ci --ignore-scripts && ant-npm-build-deptree noggin && cd gateways/noggin && npm install
