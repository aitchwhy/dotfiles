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

# Ensure script is run with sudo
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root (using sudo)"
    exit 1
fi

print_step "Starting Nix cleanup for macOS (Apple Silicon)..."

# 1. Stop and unload all Nix-related macOS services
print_step "Stopping Nix services..."
services=(
    "org.nixos.nix-daemon"
    "org.nixos.darwin-store"
    "systems.determinate.nix-installer.nix-hook"
)

for service in "${services[@]}"; do
    if [ -f "/Library/LaunchDaemons/$service.plist" ]; then
        print_substep "Unloading $service..."
        launchctl bootout system "/Library/LaunchDaemons/$service.plist" 2>/dev/null || true
        rm -f "/Library/LaunchDaemons/$service.plist"
    fi
done

# 2. Clean up macOS-specific shell configs
print_step "Cleaning shell configurations..."
shell_files=(
    "/etc/zshrc"
    "/etc/zprofile"
    "/etc/bashrc"
)

for file in "${shell_files[@]}"; do
    if [ -f "$file" ]; then
        print_substep "Cleaning $file..."
        sed -i.bak '/# Nix/d' "$file"
        sed -i.bak '/nix/d' "$file"
        if [ -f "$file.bak" ]; then
            rm "$file.bak"
        fi
    fi
done

# 3. Clean up /etc/synthetic.conf (macOS specific)
print_step "Cleaning /etc/synthetic.conf..."
if [ -f /etc/synthetic.conf ]; then
    grep -v "^nix$" /etc/synthetic.conf >/tmp/synthetic.conf.tmp
    mv /tmp/synthetic.conf.tmp /etc/synthetic.conf
fi

# 4. Remove Nix store volume using macOS diskutil
print_step "Removing Nix store volume..."
nix_volume=$(diskutil list | grep "Nix Store" | awk '{print $NF}')
if [ -n "$nix_volume" ]; then
    print_substep "Found Nix Store volume, attempting to remove..."
    diskutil apfs deleteVolume "$nix_volume" || true
    print_success "Nix Store volume removed"
else
    print_substep "No Nix Store volume found"
fi

# 5. Clean up /etc/fstab
print_step "Cleaning /etc/fstab..."
if [ -f /etc/fstab ]; then
    grep -v "/nix" /etc/fstab >/tmp/fstab.tmp && mv /tmp/fstab.tmp /etc/fstab
fi

# 6. Remove Nix files and directories
print_step "Removing Nix files and directories..."
directories=(
    "/nix"
    "/etc/nix"
    "/var/root/.nix-profile"
    "/var/root/.nix-defexpr"
    "/var/root/.nix-channels"
)

for dir in "${directories[@]}"; do
    if [ -e "$dir" ]; then
        print_substep "Removing $dir..."
        rm -rf "$dir"
    fi
done

# 7. Remove per-user files (macOS specific paths)
print_step "Removing per-user Nix files..."
for user_home in /Users/*; do
    if [ -d "$user_home" ]; then
        user=$(basename "$user_home")
        print_substep "Cleaning up for user: $user"
        user_files=(
            ".nix-profile"
            ".nix-defexpr"
            ".nix-channels"
            ".config/nix"
            ".config/nixpkgs"
            ".cache/nix"
            "Library/Caches/nix"
        )
        for file in "${user_files[@]}"; do
            rm -rf "$user_home/$file"
        done
    fi
done

# 8. Remove Nix users and groups using macOS dscl
print_step "Removing Nix users and groups..."
for i in $(seq 32 42); do
    username="nixbld$i"
    if dscl . -read "/Users/$username" &>/dev/null; then
        print_substep "Removing user $username..."
        dscl . -delete "/Users/$username" 2>/dev/null || true
    fi
done

if dscl . -read "/Groups/nixbld" &>/dev/null; then
    print_substep "Removing group nixbld..."
    dscl . -delete "/Groups/nixbld" 2>/dev/null || true
fi

# 9. Clean macOS-specific caches
print_step "Cleaning system caches..."
cache_dirs=(
    "/Library/Caches/Nix"
    "/private/var/cache/nix"
)

for dir in "${cache_dirs[@]}"; do
    if [ -e "$dir" ]; then
        print_substep "Removing $dir..."
        rm -rf "$dir"
    fi
done

# Final verification
print_step "Verifying cleanup..."
remaining_files=0
check_paths=(
    "/nix"
    "/etc/nix"
    "/Library/LaunchDaemons/org.nixos.nix-daemon.plist"
)

for path in "${check_paths[@]}"; do
    if [ -e "$path" ]; then
        print_error "Found remaining Nix component: $path"
        ((remaining_files++))
    fi
done

if [ $remaining_files -eq 0 ]; then
    print_success "Nix has been successfully uninstalled from your macOS system!"
else
    print_error "Some Nix components may still remain. Please check manually."
fi

print_step "System needs to be rebooted to complete the uninstallation"
echo -e "${YELLOW}Would you like to reboot now? (y/N)${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    shutdown -r now
fi
