#!/bin/bash

# Complete Nix + nix-darwin Uninstaller for macOS Apple Silicon
# Handles both multi-user and single-user installations
# Special handling for kernel-locked volumes
# Compatible with Nix 2.24, 2.28, and newer versions

# Ensure the script is run as root
if [[ "$(id -u)" -ne 0 ]]; then
	echo "This script must be run as root. Please use sudo."
	exit 1
fi

# Enhanced error handling
set -euo pipefail

# Helper functions for colorful output
section() { echo -e "\n\033[1;34m==== $1 ====\033[0m"; }
success() { echo -e "\033[1;32m✓ $1\033[0m"; }
warning() { echo -e "\033[1;33m⚠ $1\033[0m"; }
error() { echo -e "\033[1;31m✗ $1\033[0m"; }
info() { echo -e "\033[1;36mℹ $1\033[0m"; }

# Improved command execution with retry capability
run() {
	local cmd="$1"
	local retries=${2:-0}
	local attempt=1

	info "$ $cmd"

	while [[ "$attempt" -le "$((retries + 1))" ]]; do
		if eval "$cmd"; then
			[[ "$attempt" -gt 1 ]] && success "Command succeeded on attempt $attempt"
			return 0
		else
			local status=$?
			if [[ "$attempt" -le "$retries" ]]; then
				warning "Command failed (attempt $attempt/$((retries + 1))): $cmd (status $status)"
				warning "Retrying in 2 seconds..."
				sleep 2
			else
				error "Command failed after $attempt attempts: $cmd (status $status)"
				return "$status"
			fi
		fi
		((attempt++))
	done
	return 1 # Should not reach here, but for safety
}

run_ignore_error() {
	info "$ $1"
	eval "$1" || true
}

# Function to backup and remove files/directories
backup_and_remove() {
	local path="$1"
	local backup_dir="$2"

	if [[ -e "$path" ]]; then
		local name=$(basename "$path")
		local parent_dir=$(dirname "$path")
		local backup_path="$backup_dir/$parent_dir/$name"

		mkdir -p "$(dirname "$backup_path")"
		run_ignore_error "cp -pR '$path' '$backup_path'"
		run_ignore_error "rm -rf '$path'"
		success "Backed up and removed: $path"
	fi
}

# Create backup directory with timestamp for idempotence
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
BACKUP_DIR="/tmp/nix-uninstall-backup-$TIMESTAMP"
mkdir -p "$BACKUP_DIR"
success "Created backup directory: $BACKUP_DIR"

# Initialize flags
REBOOT_REQUIRED=false

# Determine installation type with better detection
section "Detecting Nix installation type"
if [[ -S /nix/var/nix/daemon-socket ]] || [[ -f /Library/LaunchDaemons/org.nixos.nix-daemon.plist ]] ||
	grep -q nixbld /etc/group 2>/dev/null; then
	NIX_INSTALL_TYPE="multi-user"
	success "Detected multi-user Nix installation"
else
	NIX_INSTALL_TYPE="single-user"
	success "Detected single-user Nix installation"
fi

# Phase 1: Check for kernel-locked Nix volume with enhanced detection
section "Checking for kernel-locked Nix volume"

# Find the Nix Store volume with more reliable detection
NIX_VOLUME_INFO=$(diskutil list | awk '/Nix Store|NixStore/ {getline; print}' || true)
if [[ -n "$NIX_VOLUME_INFO" ]]; then
	warning "Found Nix Store volume"
	echo "$NIX_VOLUME_INFO"

	# Get all volume identifiers (e.g., disk3s7) that match Nix Store
	NIX_VOLUME_IDS=$(diskutil list | awk '/Nix Store|NixStore/ {getline; print $NF}' || true)

	if [[ -n "$NIX_VOLUME_IDS" ]]; then
		for NIX_VOLUME_ID in $NIX_VOLUME_IDS; do
			warning "Testing volume: $NIX_VOLUME_ID"

			# Test if we can unmount it
			if ! diskutil unmount "$NIX_VOLUME_ID" >/dev/null 2>&1; then
				# Check if it's used by kernel
				if diskutil unmountDisk force "$NIX_VOLUME_ID" 2>&1 | grep -q "busy"; then
					warning "Nix Store volume $NIX_VOLUME_ID is locked by kernel"

					# Phase 1A: Disable the volume from mounting at boot
					section "Preparing for reboot - removing boot configurations"

					# Function to clean up boot configuration files
					cleanup_boot_config() {
						local file="$1"
						local pattern="$2"

						if [[ -f "$file" ]]; then
							backup_and_remove "$file" "$BACKUP_DIR"
							grep -v "$pattern" "$BACKUP_DIR/$file" >"$file"
							success "Removed nix entry from $file"
						fi
					}

					# Remove entries from synthetic.conf
					cleanup_boot_config "/etc/synthetic.conf" "^nix"

					# Remove synthetic.d/nix if it exists
					backup_and_remove "/etc/synthetic.d/nix" "$BACKUP_DIR"

					# Clean up fstab entries
					cleanup_boot_config "/etc/fstab" "nix"

					# Clean up fstab.d/nix if it exists
					backup_and_remove "/etc/fstab.d/nix" "$BACKUP_DIR"

					# We need to continue with the rest of cleanup and then prompt for reboot
					warning "IMPORTANT: You'll need to reboot after this script finishes"
					warning "After reboot, run this script again to complete volume deletion"

					# Set a flag for post-reboot notification
					REBOOT_REQUIRED=true
				else
					# Remount it since we just unmounted it for testing
					run_ignore_error "diskutil mount $NIX_VOLUME_ID"
					success "Nix Store volume $NIX_VOLUME_ID can be unmounted normally"
				fi
			else
				# Remount it since we just unmounted it for testing
				run_ignore_error "diskutil mount $NIX_VOLUME_ID"
				success "Nix Store volume $NIX_VOLUME_ID can be unmounted normally"
			fi
		done
	fi
fi

# Step 2: Try to run nix-darwin uninstaller if installed
section "Checking for nix-darwin"
if command -v darwin-rebuild >/dev/null 2>&1; then
	warning "Attempting to run nix-darwin uninstaller"
	run_ignore_error "darwin-rebuild uninstaller"
elif [[ -d /nix/store ]]; then
	warning "Attempting to run nix-darwin uninstaller via nix run"
	run_ignore_error "PATH=/nix/var/nix/profiles/default/bin:$PATH nix run github:LnL7/nix-darwin/master -- uninstaller"
fi

# Step 3: Stop Nix services with verification
section "Stopping Nix services"
if [[ "$NIX_INSTALL_TYPE" == "multi-user" ]]; then
	launchctl_action() {
		local service="$1"
		run_ignore_error "launchctl bootout system/$service 2>/dev/null"
		run_ignore_error "launchctl unload /Library/LaunchDaemons/$service.plist 2>/dev/null"
	}
	launchctl_action "org.nixos.nix-daemon"
	launchctl_action "org.nixos.darwin-store"

	# Verify services are stopped
	if launchctl list | grep -q "org.nixos"; then
		error "Some Nix services are still running, trying forced termination"
		run_ignore_error "launchctl kill SIGKILL system/org.nixos.nix-daemon 2>/dev/null"
		run_ignore_error "launchctl kill SIGKILL system/org.nixos.darwin-store 2>/dev/null"
	else
		success "Stopped multi-user Nix services"
	fi
else
	# Handle single-user services for all users
	find /Users -maxdepth 1 -type d -name "*" -print0 | while IFS= read -r -d $'\0' user_home; do
		if [[ -f "$user_home/Library/LaunchAgents/org.nixos.nix-daemon.plist" ]]; then
			local user=$(basename "$user_home")
			run_ignore_error "sudo -u \"$user\" launchctl unload \"$user_home/Library/LaunchAgents/org.nixos.nix-daemon.plist\" 2>/dev/null"
		fi
	done
	success "Stopped single-user Nix services"
fi

# Step 4: Kill any remaining Nix processes with verification
section "Terminating Nix processes"
kill_nix_processes() {
	local attempt=1
	while [[ "$attempt" -le 3 ]]; do
		local nix_pids=$(pgrep -af "nix-daemon|darwin-rebuild|nix-store" || true)
		if [[ -n "$nix_pids" ]]; then
			warning "Attempt $attempt: Terminating running Nix processes:"
			echo "$nix_pids"
			run_ignore_error "kill -TERM $nix_pids 2>/dev/null"
			sleep 1

			# Check if processes still exist on the final attempt
			if [[ "$attempt" -eq 3 ]]; then
				local remaining_pids=$(pgrep -af "nix-daemon|darwin-rebuild|nix-store" || true)
				if [[ -n "$remaining_pids" ]]; then
					warning "Forcefully killing remaining Nix processes:"
					echo "$remaining_pids"
					run_ignore_error "kill -9 $remaining_pids 2>/dev/null"
				fi
			fi
		else
			success "No running Nix processes found"
			break
		fi
		((attempt++))
	done
}
kill_nix_processes

# Step 5: Attempt to unmount /nix with retries
section "Attempting to unmount /nix"
if mount | grep -q "/nix"; then
	warning "/nix is mounted, attempting to unmount"

	# Check what's using /nix (excluding kernel processes)
	local lsof_output=$(lsof +D /nix 2>/dev/null | grep -v "^kernel" || true)
	if [[ -n "$lsof_output" ]]; then
		echo "Processes using /nix:"
		echo "$lsof_output"
		warning "Killing user processes using /nix"
		lsof +D /nix 2>/dev/null | grep -v "^kernel" | awk 'NR>1 {print $2}' | sort -u | xargs -r kill -9 2>/dev/null || true
		sleep 1
	fi

	# Try unmounting with retries
	for attempt in {1..3}; do
		warning "Unmount attempt $attempt of 3"
		if run_ignore_error "umount /nix"; then
			success "Successfully unmounted /nix"
			break
		elif [[ "$attempt" -eq 3 ]]; then
			run_ignore_error "umount -f /nix"
			if ! mount | grep -q "/nix"; then
				success "Successfully force-unmounted /nix"
			else
				warning "Could not unmount /nix - will try volume deletion later"
			fi
		fi
		sleep 2
	done
else
	success "/nix is not mounted as a separate filesystem"
fi

# Step 6: Remove LaunchDaemons and LaunchAgents with consolidated logic
section "Removing LaunchDaemons and LaunchAgents"

# Backup and remove LaunchDaemons
if [[ "$NIX_INSTALL_TYPE" == "multi-user" ]]; then
	find /Library/LaunchDaemons -name "org.nixos.*.plist" -type f -print0 | while IFS= read -r -d $'\0' daemon; do
		backup_and_remove "$daemon" "$BACKUP_DIR"
	done
fi

# Process all user LaunchAgents
find /Users/*/Library/LaunchAgents -name "org.nixos.*.plist" -type f -print0 | while IFS= read -r -d $'\0' agent; do
	local user_home=$(dirname "$(dirname "$agent")")
	local user=$(basename "$user_home")
	backup_and_remove "$agent" "$BACKUP_DIR/LaunchAgents/$user"
done

# Step 7: Remove nixbld users and group with better verification
section "Removing nixbld users and group"
if [[ "$NIX_INSTALL_TYPE" == "multi-user" ]]; then
	# Function to remove user or group with verification
	remove_dscl_entry() {
		local type="$1" # "Users" or "Groups"
		local name="$2"

		if dscl . -read "/$type/$name" >/dev/null 2>&1; then
			warning "Removing $type: $name"
			run_ignore_error "dscl . -delete \"/$type/$name\""

			# Verify removal
			if ! dscl . -read "/$type/$name" >/dev/null 2>&1; then
				success "$type $name successfully removed"
			else
				error "Failed to remove $type $name"
			fi
		else
			success "No $type $name found"
		fi
	}

	# Get a list of nixbld users first
	local nixbld_users=$(dscl . -list /Users | grep nixbld || true)
	if [[ -n "$nixbld_users" ]]; then
		for user in $nixbld_users; do
			remove_dscl_entry "Users" "$user"
		done
	fi

	# Remove nixbld group
	remove_dscl_entry "Groups" "nixbld"
fi

# Step 8: Clean up system configuration files with consolidated function
section "Cleaning up system configuration files"

# Define all files to clean up in an array
declare -a NIX_SYSTEM_FILES=(
	"/etc/nix"
	"/etc/profile.d/nix.sh"
	"/etc/profile.d/nix-daemon.sh"
	"/etc/zshrc.d/nix.sh"
	"/etc/zshrc.d/nix-daemon.sh"
	"/etc/bash.bashrc.local-nix"
	"/etc/zsh/zshrc.local-nix"
)

# Backup and remove each file
for file in "${NIX_SYSTEM_FILES[@]}"; do
	backup_and_remove "$file" "$BACKUP_DIR"
done

# Make sure synthetic.conf is cleaned again (in case we're running post-reboot)
if [[ -f /etc/synthetic.conf ]]; then
	if grep -q "^nix" /etc/synthetic.conf; then
		warning "Removing nix entry from /etc/synthetic.conf"
		grep -v "^nix" /etc/synthetic.conf >"/tmp/synthetic.conf.new"
		run "mv /tmp/synthetic.conf.new /etc/synthetic.conf"
	fi
fi

# Restore backed-up system files
restore_backup() {
	local file="$1"
	local backup="${file}.backup-before-nix"
	if [[ -f "$backup" ]]; then
		warning "Restoring original $file from backup"
		run "mv '$backup' '$file'"
	fi
}
restore_backup "/etc/bashrc"
restore_backup "/etc/zshrc"
restore_backup "/etc/bash.bashrc"
restore_backup "/etc/zsh/zshrc"

success "Cleaned up system configuration files"

# Step 9: Try to delete the APFS volume with enhanced retry logic
section "Attempting to remove Nix APFS volume"

# Get list of all Nix-related volumes with improved detection
nix_apfs_volumes=$(diskutil apfs list | grep -i "Nix.*Store\|NixStore" -B 2 -A 2 | grep "APFS Volume" || true)

# Check if /nix is on a read-only filesystem
if [[ -e "/nix" ]]; then
	if mount | grep -q "/nix.*read-only" || ! touch /nix/.test_write 2>/dev/null; then
		warning "/nix is on a read-only filesystem, attempting to remount"

		# Get the device name for /nix
		nix_device=$(mount | grep "/nix" | awk '{print $1}')

		if [[ -n "$nix_device" ]]; then
			# Attempt to remount as read-write
			warning "Attempting to remount $nix_device as read-write"
			run_ignore_error "mount -u -w \"$nix_device\""

			# Alternative method for APFS volumes
			run_ignore_error "diskutil mount -mountPoint /nix -readWrite \"$nix_device\""

			# Check if remount was successful
			if ! touch /nix/.test_write 2>/dev/null; then
				error "Failed to remount /nix as read-write"
				REBOOT_REQUIRED=true
				warning "You may need to run 'sudo diskutil resetUserPermissions / $(id -u)' after reboot"
			else
				success "Successfully remounted /nix as read-write"
				run_ignore_error "rm -f /nix/.test_write"
			fi
		else
			error "Unable to determine device for /nix mount point"
			REBOOT_REQUIRED=true
		fi
	fi
fi

# Try to remove /nix with retry
for attempt in {1..3}; do
	if [[ -e "/nix" ]]; then
		warning "Attempt $attempt to remove /nix directory"
		run_ignore_error "rm -rf /nix"

		# If failed and on final attempt, try alternative methods
		if [[ -e "/nix" ]] && [[ "$attempt" -eq 3 ]]; then
			warning "Standard removal failed, trying alternative methods"

			# Try using chflags to clear any special flags
			run_ignore_error "chflags -R nouchg,noschg,nosappnd,noarch /nix"
			run_ignore_error "rm -rf /nix"

			# If still failing, suggest more dramatic approaches
			if [[ -e "/nix" ]]; then
				warning "Unable to remove /nix directory"
				warning "You may need to disable System Integrity Protection (SIP)"
				warning "or use Recovery Mode to remove the directory"
				REBOOT_REQUIRED=true
			fi
		fi

		# Break early if successful
		[[ ! -e "/nix" ]] && break
		sleep 2
	else
		break
	fi
done

if [[ -n "$nix_apfs_volumes" ]]; then
	echo "Found the following Nix-related volumes:"
	echo "$nix_apfs_volumes"

	# Extract volume identifiers more reliably
	disk_ids=$(echo "$nix_apfs_volumes" | grep -o "disk[0-9]+s[0-9]+" || true)

	if [[ -n "$disk_ids" ]]; then
		for disk_id in $disk_ids; do
			warning "Attempting to delete volume: $disk_id"

			# Try deletion with retries
			for attempt in {1..3}; do
				delete_output=$(diskutil apfs deleteVolume "$disk_id" 2>&1)

				if echo "$delete_output" | grep -q "busy"; then
					if [[ "$attempt" -eq 3 ]]; then
						error "Volume $disk_id is busy (likely locked by kernel)"
						warning "You'll need to restart your computer and run this script again"
						REBOOT_REQUIRED=true
					else
						warning "Volume busy on attempt $attempt, retrying in 2 seconds..."
						sleep 2
					fi
				elif echo "$delete_output" | grep -q "successfully deleted"; then
					success "Successfully deleted volume: $disk_id"
					break
				else
					if [[ "$attempt" -eq 3 ]]; then
						error "Failed to delete volume $disk_id: $delete_output"
					else
						warning "Failed on attempt $attempt, retrying in 2 seconds..."
						sleep 2
					fi
				fi
			done
		done
	fi
else
	# Check if we're in post-reboot phase
	if diskutil list | grep -q "/nix"; then
		error "Nix mount point exists but no APFS volume found - unusual state"
	else
		success "No Nix APFS volumes found"
	fi
fi

# Step 10: Remove /nix directory and clean up user files with consolidated logic
section "Removing Nix directory and user files"

# Try to remove /nix with retry (again, in case volume removal failed earlier)
for attempt in {1..3}; do
	if [[ -e "/nix" ]]; then
		warning "Attempt $attempt to remove /nix directory"
		run_ignore_error "rm -rf /nix"

		[[ ! -e "/nix" ]] && break
		[[ "$attempt" -eq 3 ]] && warning "Could not remove /nix directory"
		sleep 2
	else
		break
	fi
done

# Define Nix user files to clean up
declare -a NIX_USER_FILES=(
	".nix-profile"
	".nix-defexpr"
	".nix-channels"
	".config/nixpkgs"
	".config/nix"
	".nixpkgs"
)

# Clean up user Nix files
find /Users -maxdepth 1 -type d -name "*" -print0 | while IFS= read -r -d $'\0' user_home; do
	local user=$(basename "$user_home")
	warning "Cleaning up Nix files for user: $user"
	for file in "${NIX_USER_FILES[@]}"; do
		backup_and_remove "$user_home/$file" "$BACKUP_DIR/$user"
	done
done

# Clean up root user Nix profile (separate handling for /var/root)
warning "Cleaning up Nix files for root user"
for file in "${NIX_USER_FILES[@]}"; do
	backup_and_remove "/var/root/$file" "$BACKUP_DIR/root"
done

success "Cleaned up Nix user files"

# Step 11: Final verification with more thorough checks
section "Final verification"

REBOOT_NEEDED=false

# Define verification checks
verify_check() {
	local check_name="$1"
	local check_cmd="$2"
	local failure_msg="$3"

	if eval "$check_cmd"; then
		error "$failure_msg"
		REBOOT_NEEDED=true
		return 1
	else
		success "$check_name check passed"
		return 0
	fi
}

# Run verification checks
verify_check "/nix directory" "[ -e '/nix' ]" "/nix directory still exists"
verify_check "Nix APFS volume" "diskutil apfs list 2>/dev/null | grep -qi 'Nix Store\|NixStore'" "Nix APFS volume still exists"
verify_check "nix-daemon processes" "pgrep -af 'nix-daemon' >/dev/null" "nix-daemon is still running"
verify_check "LaunchDaemons" "[ -n \"$(find /Library/LaunchDaemons -name 'org.nixos.*.plist' -type f -print0)\" ]" "Nix LaunchDaemons still exist"

# Check for remaining user LaunchAgents
remaining_agents=$(find /Users/*/Library/LaunchAgents -name "org.nixos.*.plist" -type f -print0)
if [[ -n "$remaining_agents" ]]; then
	error "Nix LaunchAgents still exist:"
	echo "$remaining_agents"
	REBOOT_NEEDED=true
else
	success "No remaining Nix LaunchAgents found"
fi

# Final instructions with clearer guidance
echo ""
echo "=================================================================="
if [[ "$REBOOT_REQUIRED" == "true" ]] || [[ "$REBOOT_NEEDED" == "true" ]]; then
	warning "IMPORTANT: You must restart your computer now!"
	echo "After restarting, run this script again to complete the uninstallation."
elif [[ -e "/nix" ]] || diskutil apfs list 2>/dev/null | grep -qi "Nix Store\|NixStore"; then
	warning "Some Nix components could not be fully removed."
	echo "Please restart your computer and run this script again."
else
	success "Nix uninstallation completed successfully!"
fi
echo ""
echo "Your Nix configuration backups are stored in: $BACKUP_DIR"
echo "You may need to manually clean up your shell configuration files:"
echo "- ~/.bashrc, ~/.bash_profile"
echo "- ~/.zshrc, ~/.zprofile"
echo "- Remove any lines that source nix.sh or add Nix to your PATH"
echo "=================================================================="

exit 0
