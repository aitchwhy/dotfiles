#!/usr/bin/env bash
# Bootstrap script for setting up nix-darwin on a fresh macOS system

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="${NIXDOTS_REPO:-https://github.com/yourusername/nixdots.git}"
NIXDOTS_PATH="${NIXDOTS_PATH:-$HOME/nixdots}"
DEFAULT_HOST="${DEFAULT_HOST:-$(hostname -s)}"

echo -e "${BLUE}🚀 Nix Darwin Bootstrap${NC}"
echo "========================"

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to prompt for confirmation
confirm() {
    local prompt="$1"
    local default="${2:-n}"
    
    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n] "
        default_val=0
    else
        prompt="$prompt [y/N] "
        default_val=1
    fi
    
    read -p "$prompt" -n 1 -r
    echo
    
    if [[ -z "$REPLY" ]]; then
        return $default_val
    elif [[ "$REPLY" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}✗ This script is only for macOS${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Prerequisites Check${NC}"
echo "==================="

# Check for Xcode Command Line Tools
echo -n "Checking Xcode Command Line Tools... "
if xcode-select -p &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}Installing...${NC}"
    xcode-select --install
    echo "Please complete the Xcode Command Line Tools installation and re-run this script."
    exit 1
fi

# Check for Homebrew (optional but recommended)
echo -n "Checking Homebrew... "
if command_exists brew; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}Not found${NC}"
    if confirm "Install Homebrew?"; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
fi

# Install Nix if not present
echo -n "Checking Nix... "
if command_exists nix; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}Installing...${NC}"
    if confirm "Install Nix?" "y"; then
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
        
        # Source nix
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
            . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi
    else
        echo -e "${RED}✗ Nix is required to continue${NC}"
        exit 1
    fi
fi

# Enable flakes
echo -n "Checking Nix flakes... "
if nix flake --version &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}Enabling...${NC}"
    mkdir -p ~/.config/nix
    echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
fi

# Clone or update repository
echo -e "\n${YELLOW}Repository Setup${NC}"
echo "================"

if [[ -d "$NIXDOTS_PATH" ]]; then
    echo "Found existing configuration at $NIXDOTS_PATH"
    if confirm "Update from git?" "y"; then
        cd "$NIXDOTS_PATH"
        git pull origin main
    fi
else
    echo "Cloning configuration repository..."
    git clone "$REPO_URL" "$NIXDOTS_PATH"
    cd "$NIXDOTS_PATH"
fi

# Detect or prompt for hostname
echo -e "\n${YELLOW}System Configuration${NC}"
echo "===================="

if [[ -f "machines/${DEFAULT_HOST}.nix" ]]; then
    echo -e "Found configuration for: ${GREEN}$DEFAULT_HOST${NC}"
    HOST="$DEFAULT_HOST"
else
    echo "Available configurations:"
    for config in machines/*.nix; do
        basename "$config" .nix
    done
    
    read -p "Enter hostname to use: " HOST
    
    if [[ ! -f "machines/${HOST}.nix" ]]; then
        echo -e "${RED}✗ Configuration not found for $HOST${NC}"
        exit 1
    fi
fi

# Install nix-darwin if not present
echo -e "\n${YELLOW}Installing nix-darwin${NC}"
echo "====================="

if command_exists darwin-rebuild; then
    echo -e "${GREEN}✓ nix-darwin already installed${NC}"
else
    echo "Installing nix-darwin..."
    nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
    ./result/bin/darwin-installer
fi

# Build and switch to configuration
echo -e "\n${YELLOW}Building Configuration${NC}"
echo "====================="

echo "Building configuration for $HOST..."
if darwin-rebuild switch --flake ".#$HOST"; then
    echo -e "${GREEN}✓ Configuration applied successfully!${NC}"
else
    echo -e "${RED}✗ Build failed${NC}"
    echo "Try running: darwin-rebuild switch --flake '.#$HOST' --show-trace"
    exit 1
fi

# Post-installation setup
echo -e "\n${YELLOW}Post-Installation${NC}"
echo "================="

# Set up shell
if [[ "$SHELL" != "/run/current-system/sw/bin/zsh" ]]; then
    if confirm "Change default shell to Nix-managed zsh?"; then
        echo "/run/current-system/sw/bin/zsh" | sudo tee -a /etc/shells
        chsh -s /run/current-system/sw/bin/zsh
    fi
fi

# Install any Homebrew casks
if command_exists brew; then
    echo "Installing Homebrew casks..."
    brew bundle --file=/dev/stdin <<-EOF
        $(nix eval --raw ".#darwinConfigurations.$HOST.config.homebrew.brewfile")
EOF
fi

# Final summary
echo -e "\n${GREEN}✅ Bootstrap Complete!${NC}"
echo "===================="
echo ""
echo "Next steps:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Run 'just' to see available commands"
echo "3. Edit your user configuration in: users/$(whoami).nix"
echo "4. Rebuild with: just switch"
echo ""
echo "For help, see: $NIXDOTS_PATH/README.md"