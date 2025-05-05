# Simple test justfile

# Default recipe to show available recipes
default:
    @just --list

# Show system information
info:
    @echo "System Information"
    @echo "=================="
    @echo "OS: $(uname -s) $(uname -r)"
    @echo "Architecture: $(uname -m)"

# Clean up system disk space
cleanup:
    @echo "Cleaning up system disk space..."
    @echo "Done!"

# Update dotfiles repo
dotfiles-update:
    @cd ~/dotfiles && git pull

# Fix Nix integration
nix-fix:
    @echo "Fixing Nix integration for the platform project..."
    @echo "This would run the fix script if this was not a test"