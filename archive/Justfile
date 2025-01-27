# Just command runner (https://github.com/casey/just)

# List available commands
default:
    @just --list

# Build and switch to the new configuration for the current host
switch hostname=`hostname -s`:
    darwin-rebuild switch --flake .#{{hostname}}

# Build and switch to the new configuration for the current host with verbose output
switch-debug hostname=`hostname -s`:
    darwin-rebuild switch --flake .#{{hostname}} --verbose --show-trace

# Update all flake inputs
update:
    nix flake update

# Update specific flake input
update-input input:
    nix flake lock --update-input {{input}}

# Clean up old generations
clean:
    sudo nix-collect-garbage -d
    nix-collect-garbage -d

# Check flake
check:
    nix flake check

# Format nix files
fmt:
    nix fmt

# Build configuration without switching
build hostname=`hostname -s`:
    darwin-rebuild build --flake .#{{hostname}}

# Edit configuration in $EDITOR
edit:
    $EDITOR .

# Show system closure difference
diff hostname=`hostname -s`:
    darwin-rebuild build --flake .#{{hostname}} --show-trace -v
    nix store diff-closures /run/current-system ./result
