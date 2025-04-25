#!/bin/zsh
#
# nix-uninstall-macos.sh
# Script to completely uninstall a multi-user Nix installation on macOS
# Based on the Nix Reference Manual

# Check if running on macOS
if [[ $(uname) != "Darwin" ]]; then
	echo "Error: This script is only for macOS systems."
	exit 1
fi

# Check if running with sudo/root privileges
if [[ $EUID -ne 0 ]]; then
	echo "Error: This script must be run with sudo privileges."
	echo "Please run: sudo $0"
	exit 1
fi

echo "Starting Nix uninstallation (multi-user mode)..."

# 1. Restore original shell configuration files if backups exist
echo "Restoring shell configuration files..."
sudo mv /etc/zshrc.backup-before-nix /etc/zshrc 2>/dev/null || true
sudo mv /etc/bashrc.backup-before-nix /etc/bashrc 2>/dev/null || true
sudo mv /etc/bash.bashrc.backup-before-nix /etc/bash.bashrc 2>/dev/null || true

# 2. Stop and remove Nix daemon services
echo "Stopping and removing Nix daemon services..."
sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true
sudo rm /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true
sudo launchctl unload /Library/LaunchDaemons/org.nixos.darwin-store.plist 2>/dev/null || true
sudo rm /Library/LaunchDaemons/org.nixos.darwin-store.plist 2>/dev/null || true

# 3. Remove the nixbld group and all _nixbld users
echo "Removing nixbld group and build users..."
sudo dscl . -delete /Groups/nixbld 2>/dev/null || true
for u in $(sudo dscl . -list /Users | grep _nixbld); do
	sudo dscl . -delete /Users/$u 2>/dev/null || true
done

# 4. Clean Nix references from fstab
echo "Cleaning up fstab entries..."
sudo sed -i "" "/nix/d" /etc/fstab 2>/dev/null || true

# 5. Clean up synthetic.conf
echo "Cleaning up synthetic.conf..."
if [ -f /etc/synthetic.conf ]; then
	sudo sed -i "" "/^nix$/d" /etc/synthetic.conf
	# Remove the file if it's empty after our edit
	if [ ! -s /etc/synthetic.conf ]; then
		sudo rm /etc/synthetic.conf
	fi
fi

# 6. Remove all Nix-related files from the system
echo "Removing Nix-related files..."
sudo rm -rf /etc/nix \
	/var/root/.nix-profile \
	/var/root/.nix-defexpr \
	/var/root/.nix-channels \
	~/.nix-profile \
	~/.nix-defexpr \
	~/.nix-channels

# 7. Delete the Nix Store volume
echo "Removing Nix Store volume..."
if ! sudo diskutil apfs deleteVolume /nix 2>/dev/null; then
	echo "Could not remove volume at /nix. Checking for unmounted Nix Store volume..."

	# Output disk list for the user to check
	echo "Looking for 'Nix Store' volume in disk list:"
	diskutil list | grep -A 1 -B 1 "Nix Store" || echo "No 'Nix Store' volume found in disk list."

	echo "If you see a 'Nix Store' volume above, note its disk identifier (e.g., disk3s5)"
	echo "and run: sudo diskutil apfs deleteVolume <disk-identifier>"
fi

echo "Nix uninstallation complete!"
echo "Note: An empty /nix directory might remain until you reboot."
echo "      This is normal and expected behavior."
