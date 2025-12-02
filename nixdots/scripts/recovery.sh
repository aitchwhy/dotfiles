#!/usr/bin/env bash
# Recovery script for broken nix-darwin configurations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}🚨 Nix Darwin Recovery${NC}"
echo "====================="
echo ""
echo "This script helps recover from broken configurations."
echo ""

# Function to prompt for confirmation
confirm() {
    local prompt="$1"
    read -p "$prompt [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Function to list generations
list_generations() {
    echo -e "${YELLOW}Available system generations:${NC}"
    darwin-rebuild --list-generations 2>/dev/null || {
        echo -e "${RED}Unable to list generations${NC}"
        echo "You may need to check /nix/var/nix/profiles/system-*"
        return 1
    }
}

# Main recovery menu
while true; do
    echo -e "\n${BLUE}Recovery Options:${NC}"
    echo "1. Roll back to previous generation"
    echo "2. Roll back to specific generation"
    echo "3. Fix Nix store permissions"
    echo "4. Repair Nix store"
    echo "5. Clean build and garbage collection"
    echo "6. Reset to minimal configuration"
    echo "7. Show diagnostic information"
    echo "8. Emergency shell configuration"
    echo "9. Exit"
    echo ""
    
    read -p "Select option (1-9): " choice
    
    case $choice in
        1)
            echo -e "\n${YELLOW}Rolling back to previous generation...${NC}"
            if darwin-rebuild --rollback; then
                echo -e "${GREEN}✓ Rollback successful${NC}"
                echo "Please restart your shell or logout/login"
            else
                echo -e "${RED}✗ Rollback failed${NC}"
            fi
            ;;
            
        2)
            list_generations
            echo ""
            read -p "Enter generation number to roll back to: " gen_num
            
            if [[ "$gen_num" =~ ^[0-9]+$ ]]; then
                echo -e "\n${YELLOW}Rolling back to generation $gen_num...${NC}"
                if darwin-rebuild switch -G "$gen_num"; then
                    echo -e "${GREEN}✓ Rollback successful${NC}"
                else
                    echo -e "${RED}✗ Rollback failed${NC}"
                fi
            else
                echo -e "${RED}Invalid generation number${NC}"
            fi
            ;;
            
        3)
            echo -e "\n${YELLOW}Fixing Nix store permissions...${NC}"
            
            # Fix store permissions
            sudo chown -R root:nixbld /nix/store
            sudo chmod 1775 /nix/store
            
            # Fix var permissions
            sudo chown -R root:nixbld /nix/var/nix
            sudo chmod -R 755 /nix/var/nix
            
            # Fix daemon socket
            sudo chown root:daemon /nix/var/nix/daemon-socket
            sudo chmod 666 /nix/var/nix/daemon-socket/socket
            
            echo -e "${GREEN}✓ Permissions fixed${NC}"
            ;;
            
        4)
            echo -e "\n${YELLOW}Repairing Nix store...${NC}"
            echo "This will verify and repair the Nix store. It may take a while."
            
            if confirm "Continue?"; then
                sudo nix-store --verify --check-contents --repair
                echo -e "${GREEN}✓ Store repair complete${NC}"
            fi
            ;;
            
        5)
            echo -e "\n${YELLOW}Cleaning build artifacts and collecting garbage...${NC}"
            
            # Remove result symlinks
            find . -type l -name "result" -exec rm {} \; 2>/dev/null || true
            
            # Clear Nix build cache
            nix-collect-garbage -d
            
            # Optimize store
            nix-store --optimise
            
            echo -e "${GREEN}✓ Cleanup complete${NC}"
            ;;
            
        6)
            echo -e "\n${YELLOW}Reset to minimal configuration${NC}"
            echo "This will create a minimal working configuration."
            
            if confirm "This will backup and replace your current flake.nix. Continue?"; then
                # Backup current configuration
                cp flake.nix "flake.nix.backup.$(date +%Y%m%d_%H%M%S)"
                
                # Create minimal flake
                cat > flake.nix << 'EOF'
{
  description = "Minimal Recovery Configuration";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };
  
  outputs = { self, nixpkgs, nix-darwin }:
  let
    configuration = { pkgs, ... }: {
      # Minimal system packages
      environment.systemPackages = with pkgs; [
        vim
        git
      ];
      
      # Auto upgrade nix package and daemon
      services.nix-daemon.enable = true;
      nix.package = pkgs.nix;
      
      # Necessary for using flakes
      nix.settings.experimental-features = "nix-command flakes";
      
      # Platform settings
      nixpkgs.hostPlatform = "aarch64-darwin";
      system.stateVersion = 4;
      
      # User
      users.users.$USER = {
        name = "$USER";
        home = "/Users/$USER";
      };
    };
  in
  {
    darwinConfigurations."$(hostname -s)" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };
  };
}
EOF
                echo -e "${GREEN}✓ Minimal configuration created${NC}"
                echo "Run: darwin-rebuild switch --flake ."
            fi
            ;;
            
        7)
            echo -e "\n${YELLOW}Diagnostic Information${NC}"
            echo "====================="
            
            echo -e "\n${BLUE}System:${NC}"
            echo "  Hostname: $(hostname)"
            echo "  macOS: $(sw_vers -productVersion)"
            echo "  Nix: $(nix --version 2>/dev/null || echo 'Not working')"
            
            echo -e "\n${BLUE}Current Generation:${NC}"
            if [[ -L /run/current-system ]]; then
                echo "  Path: $(readlink /run/current-system)"
                echo "  Date: $(stat -f "%Sm" /run/current-system)"
            else
                echo "  ${RED}No current system link${NC}"
            fi
            
            echo -e "\n${BLUE}Nix Daemon:${NC}"
            if launchctl list | grep -q org.nixos.nix-daemon; then
                echo "  ${GREEN}✓ Running${NC}"
            else
                echo "  ${RED}✗ Not running${NC}"
                echo "  Try: sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist"
            fi
            
            echo -e "\n${BLUE}Store Status:${NC}"
            df -h /nix/store 2>/dev/null || echo "  Unable to check"
            ;;
            
        8)
            echo -e "\n${YELLOW}Emergency Shell Configuration${NC}"
            echo "Creating temporary shell configuration..."
            
            # Create emergency bashrc
            cat > ~/.bashrc.emergency << 'EOF'
# Emergency shell configuration
export PATH="/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export NIX_PATH="nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs:/nix/var/nix/profiles/per-user/root/channels"

alias nix-repair='sudo nix-store --verify --check-contents --repair'
alias nix-gc='nix-collect-garbage -d'
alias rebuild='darwin-rebuild switch --flake ~/nixdots'

echo "Emergency shell active. Your normal configuration may be broken."
echo "Use 'nix-repair' to fix store issues."
echo "Use 'darwin-rebuild --rollback' to revert to previous generation."
EOF
            
            echo -e "${GREEN}✓ Emergency configuration created${NC}"
            echo "Run: source ~/.bashrc.emergency"
            ;;
            
        9)
            echo "Exiting recovery mode."
            exit 0
            ;;
            
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
done