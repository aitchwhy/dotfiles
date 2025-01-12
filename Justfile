# Just commands for managing nix-darwin system

# List available commands
default:
    @just --list

# Build the current system
build hostname="hank-mstio":
    nix build .#darwinConfigurations.{{hostname}}.system

# Switch to the new configuration
switch hostname="hank-mstio":
    ./result/sw/bin/darwin-rebuild switch --flake .#{{hostname}}

# Build and switch in one command
update hostname="hank-mstio": (build hostname) (switch hostname)

# Check configuration without switching
check hostname="hank-mstio":
    nix eval .#darwinConfigurations.{{hostname}}.system

# Clean up old generations
clean:
    sudo nix-collect-garbage -d
    darwin-rebuild clean

# Update flake inputs
update-flake:
    nix flake update

# Format nix files
fmt:
    nix fmt

# Show system information
info:
    darwin-rebuild --version
    nix --version
    sw_vers

# Show flake information
show:
    nix flake show

# Show flake metadata
meta:
    nix flake metadata

# List current system generations
generations:
    darwin-rebuild --list-generations

# Diff against current generation
diff hostname="hank-mstio":
    nix store diff-closures /run/current-system ./result/sw/bin/darwin-rebuild

# Build and test without switching
test hostname="hank-mstio":
    darwin-rebuild test --flake .#{{hostname}}

# Update and rebuild everything
full-update hostname="hank-mstio":
    just update-flake
    just update {{hostname}}
    just clean

# Bootstrap a new system
bootstrap hostname="hank-mstio":
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Check if nix is installed
    if ! command -v nix >/dev/null 2>&1; then
        echo "Installing Nix..."
        curl -L https://nixos.org/nix/install | sh
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
    
    # Check if homebrew is installed
    if ! command -v brew >/dev/null 2>&1; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Enable flakes
    mkdir -p ~/.config/nix
    echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
    
    # Install nix-darwin
    if ! command -v darwin-rebuild >/dev/null 2>&1; then
        echo "Installing nix-darwin..."
        nix build .#darwinConfigurations.{{hostname}}.system
        ./result/sw/bin/darwin-rebuild switch --flake .#{{hostname}}
    fi
