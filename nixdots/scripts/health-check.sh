#!/usr/bin/env bash
# Health check script for nix-darwin configuration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0

echo -e "${BLUE}🏥 Nix Darwin Health Check${NC}"
echo "=========================="
echo ""

# Function to check command
check_command() {
    local cmd="$1"
    local name="${2:-$cmd}"
    
    echo -n "  $name: "
    if command -v "$cmd" &> /dev/null; then
        local version=$(eval "$cmd --version 2>&1 | head -1" || echo "unknown")
        echo -e "${GREEN}✓${NC} ($version)"
        return 0
    else
        echo -e "${RED}✗ Not found${NC}"
        ((ERRORS++))
        return 1
    fi
}

# Function to check file/directory
check_path() {
    local path="$1"
    local type="$2" # "file" or "directory"
    local name="$3"
    
    echo -n "  $name: "
    if [[ "$type" == "file" && -f "$path" ]] || [[ "$type" == "directory" && -d "$path" ]]; then
        echo -e "${GREEN}✓${NC} ($path)"
        return 0
    else
        echo -e "${RED}✗ Not found${NC}"
        ((ERRORS++))
        return 1
    fi
}

# Function to check service
check_service() {
    local service="$1"
    local name="${2:-$service}"
    
    echo -n "  $name: "
    if launchctl list | grep -q "$service"; then
        echo -e "${GREEN}✓ Running${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Not running${NC}"
        ((WARNINGS++))
        return 1
    fi
}

# System Information
echo -e "${YELLOW}System Information${NC}"
echo "=================="
echo "  Hostname: $(hostname)"
echo "  macOS: $(sw_vers -productVersion)"
echo "  Architecture: $(uname -m)"
echo "  Nix version: $(nix --version)"
echo ""

# Core Components
echo -e "${YELLOW}Core Components${NC}"
echo "==============="
check_command "nix" "Nix"
check_command "darwin-rebuild" "Darwin Rebuild"
check_command "home-manager" "Home Manager"
check_command "nix-env" "Nix Env"
echo ""

# Configuration Files
echo -e "${YELLOW}Configuration Files${NC}"
echo "==================="
check_path "$HOME/nixdots/flake.nix" "file" "Flake configuration"
check_path "$HOME/nixdots/flake.lock" "file" "Flake lock"
check_path "/run/current-system" "directory" "Current system"
check_path "$HOME/.config/nix" "directory" "Nix config directory"
echo ""

# Nix Store Health
echo -e "${YELLOW}Nix Store${NC}"
echo "========="
echo -n "  Store directory: "
if [[ -d "/nix/store" ]]; then
    echo -e "${GREEN}✓${NC}"
    
    # Check store size
    STORE_SIZE=$(du -sh /nix/store 2>/dev/null | awk '{print $1}' || echo "unknown")
    echo "  Store size: $STORE_SIZE"
    
    # Check for corruption
    echo -n "  Store integrity: "
    if nix-store --verify --check-contents &>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗ Corrupted${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${RED}✗${NC}"
    ((ERRORS++))
fi
echo ""

# System Profile
echo -e "${YELLOW}System Profile${NC}"
echo "=============="
echo -n "  Current generation: "
CURRENT_GEN=$(darwin-rebuild --list-generations 2>/dev/null | tail -1 | awk '{print $1}' || echo "unknown")
echo "$CURRENT_GEN"

echo -n "  Profile link: "
if [[ -L "/run/current-system" ]]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    ((ERRORS++))
fi
echo ""

# Environment Variables
echo -e "${YELLOW}Environment${NC}"
echo "==========="
echo -n "  NIX_PATH: "
if [[ -n "${NIX_PATH:-}" ]]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠ Not set${NC}"
    ((WARNINGS++))
fi

echo -n "  PATH contains nix: "
if echo "$PATH" | grep -q "/nix/store"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    ((ERRORS++))
fi
echo ""

# Services
echo -e "${YELLOW}Services${NC}"
echo "========="
check_service "org.nixos.nix-daemon" "Nix Daemon"
if [[ -f "$HOME/nixdots/machines/$(hostname -s).nix" ]] && grep -q "tailscale" "$HOME/nixdots/machines/$(hostname -s).nix"; then
    check_service "com.tailscale.tailscaled" "Tailscale"
fi
echo ""

# Shell Configuration
echo -e "${YELLOW}Shell Configuration${NC}"
echo "==================="
echo -n "  Current shell: "
echo "$SHELL"

echo -n "  Zsh from Nix: "
if [[ "$SHELL" == "/run/current-system/sw/bin/zsh" ]]; then
    echo -e "${GREEN}✓${NC}"
elif which zsh | grep -q "/nix/store"; then
    echo -e "${YELLOW}⚠ Using Nix zsh but not as login shell${NC}"
    ((WARNINGS++))
else
    echo -e "${YELLOW}⚠ Not using Nix zsh${NC}"
    ((WARNINGS++))
fi
echo ""

# Flake Status
echo -e "${YELLOW}Flake Status${NC}"
echo "============"
cd "$HOME/nixdots" 2>/dev/null || cd .

echo -n "  Git repository: "
if git rev-parse --git-dir &>/dev/null; then
    echo -e "${GREEN}✓${NC}"
    
    echo -n "  Git status: "
    if [[ -z "$(git status --porcelain)" ]]; then
        echo -e "${GREEN}✓ Clean${NC}"
    else
        echo -e "${YELLOW}⚠ Uncommitted changes${NC}"
        ((WARNINGS++))
    fi
    
    echo -n "  Flake inputs: "
    OUTDATED=$(nix flake metadata --json 2>/dev/null | jq -r '.locks.nodes.root.inputs | length' || echo 0)
    echo "$OUTDATED inputs tracked"
else
    echo -e "${RED}✗${NC}"
    ((ERRORS++))
fi
echo ""

# Quick Tests
echo -e "${YELLOW}Quick Tests${NC}"
echo "==========="

echo -n "  Flake evaluation: "
if nix flake check --no-build &>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    ((ERRORS++))
fi

echo -n "  Module syntax: "
if find "$HOME/nixdots/modules" -name "*.nix" -exec nix-instantiate --parse {} \; &>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    ((ERRORS++))
fi
echo ""

# Performance Metrics
echo -e "${YELLOW}Performance Metrics${NC}"
echo "==================="
echo -n "  Evaluation time: "
EVAL_START=$(date +%s)
nix eval "$HOME/nixdots#darwinConfigurations.$(hostname -s).system" &>/dev/null
EVAL_END=$(date +%s)
EVAL_TIME=$((EVAL_END - EVAL_START))
if [[ $EVAL_TIME -lt 10 ]]; then
    echo -e "${GREEN}${EVAL_TIME}s${NC}"
elif [[ $EVAL_TIME -lt 30 ]]; then
    echo -e "${YELLOW}${EVAL_TIME}s${NC}"
else
    echo -e "${RED}${EVAL_TIME}s${NC}"
    ((WARNINGS++))
fi

echo -n "  Garbage collection: "
LAST_GC=$(stat -f "%Sm" /nix/var/nix/gcroots/auto 2>/dev/null || echo "Never")
echo "$LAST_GC"
echo ""

# Summary
echo -e "${BLUE}Summary${NC}"
echo "======="
if [[ $ERRORS -eq 0 ]]; then
    if [[ $WARNINGS -eq 0 ]]; then
        echo -e "${GREEN}✅ All checks passed!${NC}"
        echo "Your Nix Darwin system is healthy."
        exit 0
    else
        echo -e "${YELLOW}⚠ Passed with $WARNINGS warnings${NC}"
        echo "Your system is functional but could be improved."
        exit 0
    fi
else
    echo -e "${RED}✗ Failed with $ERRORS errors and $WARNINGS warnings${NC}"
    echo ""
    echo "Suggested fixes:"
    if ! command -v nix &>/dev/null; then
        echo "  - Install Nix: curl -L https://nixos.org/nix/install | sh"
    fi
    if ! command -v darwin-rebuild &>/dev/null; then
        echo "  - Install nix-darwin: nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer"
    fi
    if [[ ! -d "$HOME/nixdots" ]]; then
        echo "  - Clone your configuration: git clone <your-repo> ~/nixdots"
    fi
    exit 1
fi