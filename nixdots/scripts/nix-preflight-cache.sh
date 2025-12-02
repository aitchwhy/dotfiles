#!/usr/bin/env bash
# nix-preflight-cache.sh - Pre-flight cache warming script for offline Nix development
# This script ensures all necessary derivations are cached locally before going offline

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Ensure we're in the flake directory
FLAKE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$FLAKE_DIR"

log_info "Starting Nix pre-flight cache warming..."
log_info "Flake directory: $FLAKE_DIR"

# Check if local binary cache exists
if [ ! -d "/var/cache/nix-binary-cache" ]; then
    log_warn "Local binary cache directory doesn't exist. It will be created when you rebuild the system."
    log_warn "Run 'darwin-rebuild switch --flake .' first to set up the cache directory."
fi

# Function to cache a derivation and its dependencies
cache_derivation() {
    local desc="$1"
    local drv="$2"
    
    log_info "Caching $desc..."
    
    # Build and fetch all dependencies
    if nix build --no-link "$drv" 2>/dev/null; then
        log_success "Built $desc"
        
        # Copy to local cache if it exists
        if [ -d "/var/cache/nix-binary-cache" ]; then
            nix copy --to "file:///var/cache/nix-binary-cache" "$drv" 2>/dev/null || true
        fi
    else
        log_warn "Failed to build $desc (may not be available for this system)"
    fi
}

# Function to find and cache all development shells
cache_dev_shells() {
    log_info "Looking for development shells..."
    
    # Get all devShell outputs
    local shells=$(nix flake show --json 2>/dev/null | jq -r '.devShells // {} | to_entries[] | .key' || echo "")
    
    if [ -n "$shells" ]; then
        for system in $shells; do
            local system_shells=$(nix flake show --json 2>/dev/null | jq -r ".devShells.\"$system\" // {} | keys[]" || echo "")
            for shell in $system_shells; do
                cache_derivation "devShell.$system.$shell" ".#devShells.$system.$shell"
            done
        done
    fi
}

# Function to find current system
get_current_system() {
    nix eval --impure --expr 'builtins.currentSystem' --raw 2>/dev/null || echo "$(uname -m)-$(uname -s | tr '[:upper:]' '[:lower:]')"
}

# Main caching routine
main() {
    local system=$(get_current_system)
    local hostname=$(hostname -s)
    
    log_info "Current system: $system"
    log_info "Hostname: $hostname"
    
    # Update flake lock file
    log_info "Updating flake inputs..."
    nix flake update
    
    # Cache the Darwin system configuration
    if [[ "$OSTYPE" == "darwin"* ]]; then
        cache_derivation "Darwin system configuration" ".#darwinConfigurations.$hostname.system"
        
        # Cache the specific configuration
        cache_derivation "Darwin configuration for $hostname" ".#darwinConfigurations.$hostname.config.system.build.toplevel"
    fi
    
    # Cache home-manager configurations
    log_info "Caching home-manager configurations..."
    if [ -d "/nix/var/nix/profiles/per-user" ]; then
        for user in /nix/var/nix/profiles/per-user/*; do
            if [ -d "$user" ]; then
                username=$(basename "$user")
                cache_derivation "Home configuration for $username" ".#homeConfigurations.$username.activationPackage" || true
            fi
        done
    fi
    
    # Cache all development shells
    cache_dev_shells
    
    # Cache common tools and packages
    log_info "Caching common development tools..."
    local common_packages=(
        "nixpkgs#git"
        "nixpkgs#ripgrep"
        "nixpkgs#fd"
        "nixpkgs#bat"
        "nixpkgs#eza"
        "nixpkgs#fzf"
        "nixpkgs#delta"
        "nixpkgs#direnv"
        "nixpkgs#nixpkgs-fmt"
        "nixpkgs#nixd"
    )
    
    for pkg in "${common_packages[@]}"; do
        cache_derivation "Package $pkg" "$pkg"
    done
    
    # Cache flake outputs
    log_info "Caching flake outputs..."
    cache_derivation "Formatter" ".#formatter.$system"
    
    # Cache all apps
    local apps=$(nix flake show --json 2>/dev/null | jq -r ".apps.\"$system\" // {} | keys[]" || echo "")
    for app in $apps; do
        cache_derivation "App $app" ".#apps.$system.$app"
    done
    
    # Run garbage collection to remove old generations but keep recent ones
    log_info "Running store optimization..."
    nix-store --optimise
    
    # Show cache statistics
    log_info "Cache statistics:"
    if [ -d "/var/cache/nix-binary-cache" ]; then
        local cache_size=$(du -sh /var/cache/nix-binary-cache 2>/dev/null | cut -f1)
        log_info "Local binary cache size: $cache_size"
    fi
    
    local store_size=$(du -sh /nix/store 2>/dev/null | cut -f1)
    log_info "Nix store size: $store_size"
    
    local num_paths=$(find /nix/store -maxdepth 1 -type d | wc -l)
    log_info "Number of store paths: $num_paths"
    
    log_success "Pre-flight cache warming complete!"
    log_info "Your system is now ready for offline development."
    log_info ""
    log_info "To test offline mode:"
    log_info "  1. Disconnect from the internet"
    log_info "  2. Run: nix build --offline .#darwinConfigurations.$hostname.system"
    log_info "  3. Run: nix develop --offline"
}

# Run main function
main "$@"