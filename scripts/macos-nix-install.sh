#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_substep() {
    echo -e "${YELLOW}  ->${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if running on macOS
if [ "$(uname)" != "Darwin" ]; then
    print_error "This script is for macOS only!"
    exit 1
fi

# Check if running on Apple Silicon
if [ "$(uname -m)" != "arm64" ]; then
    print_error "This script is for Apple Silicon Macs only!"
    exit 1
fi

# Function to verify Nix installation
verify_nix_install() {
    print_step "Verifying Nix installation..."
    
    # Check if nix command exists
    if ! command -v nix &> /dev/null; then
        print_error "Nix command not found"
        return 1
    fi
    
    # Check if nix-daemon is running
    if ! launchctl list | grep -q "org.nixos.nix-daemon"; then
        print_error "Nix daemon not running"
        return 1
    }
    
    # Try running a simple nix command
    if ! nix --version &> /dev/null; then
        print_error "Nix command not working properly"
        return 1
    }
    
    print_success "Nix installation verified successfully!"
    return 0
}

# Function to configure Nix
configure_nix() {
    print_step "Configuring Nix..."
    
    # Create nix config directory
    mkdir -p ~/.config/nix
    
    # Configure experimental features
    echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
    
    print_success "Nix configuration completed!"
}

# Function to install Determinate Nix
install_determinate_nix() {
    print_step "Installing Nix using Determinate Systems installer..."
    
    # Download and run the Determinate Systems installer
    if curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install; then
        print_success "Determinate Nix installation completed!"
        configure_nix
        return 0
    else
        print_error "Determinate Nix installation failed!"
        return 1
    fi
}

# Function to install official Nix
install_official_nix() {
    print_step "Installing Nix using official installer..."
    
    # Download and run the official installer
    if curl -L https://nixos.org/nix/install | sh -s -- --daemon; then
        print_success "Official Nix installation completed!"
        configure_nix
        return 0
    else
        print_error "Official Nix installation failed!"
        return 1
    fi
}

# Main menu
show_menu() {
    echo
    echo "Nix Installer for macOS (Apple Silicon)"
    echo "======================================="
    echo "1) Install Nix using Determinate Systems (Recommended)"
    echo "2) Install Nix using official installer"
    echo "3) Verify Nix installation"
    echo "4) Exit"
    echo
    echo -n "Please select an option (1-4): "
}

# Install loop
while true; do
    show_menu
    read -r choice
    
    case $choice in
        1)
            if install_determinate_nix; then
                if verify_nix_install; then
                    print_success "Determinate Nix installation and verification complete!"
                    print_step "Please restart your terminal or run: source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
                    exit 0
                fi
            fi
            ;;
        2)
            if install_official_nix; then
                if verify_nix_install; then
                    print_success "Official Nix installation and verification complete!"
                    print_step "Please restart your terminal or run: source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
                    exit 0
                fi
            fi
            ;;
        3)
            verify_nix_install
            ;;
        4)
            print_step "Exiting..."
            exit 0
            ;;
        *)
            print_error "Invalid option"
            ;;
    esac
    
    echo
    echo -n "Press Enter to continue..."
    read -r
done