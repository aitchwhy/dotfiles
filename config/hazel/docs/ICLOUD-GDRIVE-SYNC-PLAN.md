# iCloud → Google Drive One-Way Sync Implementation Plan
**Date:** 2026-02-01
**Status:** Research Complete, Ready to Implement

---

## Research Summary

### Key Findings (Feb 2026)

**Challenge:**
Apple officially [doesn't support](https://support.apple.com/en-us/109344) simultaneous syncing of Desktop/Documents to both iCloud and Google Drive natively.

**Solution:**
Keep iCloud Desktop/Documents active (primary), create automated **one-way backup** to Google Drive using modern cloud sync tools.

### Recommended Approach: **rclone + launchd**

**Why rclone over rsync:**
- Native support for both iCloud Drive and Google Drive
- Better cloud storage compatibility
- Handles cloud-specific features (.icloud placeholders, etc.)
- More reliable than traditional rsync for cloud-to-cloud

**Why launchd over cron:**
- Runs reliably after sleep/power events
- macOS native daemon manager
- Better system integration

---

## Implementation Architecture

### Folder Structure

```
Google Drive/
└── iCloud-Mirror/              # Dedicated backup folder
    ├── Desktop/                # One-way sync from ~/Desktop
    ├── Documents/              # One-way sync from ~/Documents
    └── .sync-metadata/         # rclone sync logs and state
```

### Sync Flow

```
~/Desktop (iCloud)     →  [rclone sync]  →  Google Drive/iCloud-Mirror/Desktop/
~/Documents (iCloud)   →  [rclone sync]  →  Google Drive/iCloud-Mirror/Documents/
```

**Direction:** One-way only (iCloud → Google Drive)
**Frequency:** Every 6 hours (adjustable)
**Method:** Incremental sync (only changed files)

---

## Installation Steps

### Step 1: Install rclone

```bash
# Via Homebrew
brew install rclone

# Or via Nix (already in your setup)
# Add to modules/homebrew.nix brews section
```

### Step 2: Configure rclone

```bash
# Interactive setup for Google Drive
rclone config

# Follow prompts:
# 1. n (new remote)
# 2. name: gdrive
# 3. Storage: drive (Google Drive)
# 4. client_id: <leave blank for default>
# 5. client_secret: <leave blank>
# 6. scope: 1 (Full access)
# 7. Follow OAuth flow in browser
# 8. Confirm configuration
# 9. q (quit)
```

### Step 3: Create Google Drive backup folder

```bash
# Create mirror directory in Google Drive
rclone mkdir "gdrive:iCloud-Mirror"
rclone mkdir "gdrive:iCloud-Mirror/Desktop"
rclone mkdir "gdrive:iCloud-Mirror/Documents"
rclone mkdir "gdrive:iCloud-Mirror/.sync-metadata"
```

### Step 4: Create sync script

**Location:** `~/dotfiles/scripts/sync-icloud-to-gdrive.sh`

```bash
#!/bin/bash
# Sync iCloud Desktop & Documents to Google Drive
# One-way sync: iCloud → Google Drive only

LOG_FILE="$HOME/Library/Logs/icloud-gdrive-sync.log"
RCLONE_CONFIG="$HOME/.config/rclone/rclone.conf"

# Ensure log directory exists
mkdir -p "$HOME/Library/Logs"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting iCloud → Google Drive sync" >> "$LOG_FILE"

# Sync Desktop (exclude system files)
rclone sync \
  "$HOME/Desktop" \
  "gdrive:iCloud-Mirror/Desktop" \
  --exclude ".DS_Store" \
  --exclude ".localized" \
  --exclude "*.icloud" \
  --exclude ".Trash" \
  --log-file="$LOG_FILE" \
  --log-level INFO \
  --stats 1m \
  --transfers 4 \
  --checkers 8 \
  --copy-links \
  --no-update-modtime

# Sync Documents (exclude system files)
rclone sync \
  "$HOME/Documents" \
  "gdrive:iCloud-Mirror/Documents" \
  --exclude ".DS_Store" \
  --exclude ".localized" \
  --exclude "*.icloud" \
  --exclude ".Trash" \
  --log-file="$LOG_FILE" \
  --log-level INFO \
  --stats 1m \
  --transfers 4 \
  --checkers 8 \
  --copy-links \
  --no-update-modtime

echo "$(date '+%Y-%m-%d %H:%M:%S') - Sync completed" >> "$LOG_FILE"
```

### Step 5: Create launchd plist

**Location:** `~/Library/LaunchAgents/com.user.icloud-gdrive-sync.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.icloud-gdrive-sync</string>

    <key>ProgramArguments</key>
    <array>
        <string>/Users/hank/dotfiles/scripts/sync-icloud-to-gdrive.sh</string>
    </array>

    <key>StartInterval</key>
    <integer>21600</integer>  <!-- 6 hours in seconds -->

    <key>RunAtLoad</key>
    <true/>

    <key>StandardOutPath</key>
    <string>/Users/hank/Library/Logs/icloud-gdrive-sync-stdout.log</string>

    <key>StandardErrorPath</key>
    <string>/Users/hank/Library/Logs/icloud-gdrive-sync-stderr.log</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin</string>
    </dict>
</dict>
</plist>
```

### Step 6: Load launchd agent

```bash
# Load the agent
launchctl load ~/Library/LaunchAgents/com.user.icloud-gdrive-sync.plist

# Verify it's running
launchctl list | grep icloud-gdrive-sync

# Trigger manual run for testing
launchctl start com.user.icloud-gdrive-sync

# Check logs
tail -f ~/Library/Logs/icloud-gdrive-sync.log
```

---

## Key Features

### Excludes (What Won't Sync)
- `.DS_Store` - macOS metadata
- `.localized` - macOS folder name translations
- `*.icloud` - Placeholder files for cloud-only content
- `.Trash` - Deleted files

### Handles .icloud Placeholders
- `--copy-links` flag ensures symbolic links are followed
- Only syncs files that are actually downloaded locally
- Won't attempt to sync cloud-only placeholder files

### Performance
- `--transfers 4` - Upload 4 files simultaneously
- `--checkers 8` - Check 8 files at once for changes
- `--stats 1m` - Progress updates every minute
- Incremental sync - only changed files uploaded

### Safety
- One-way sync only (no deletions from iCloud)
- `--no-update-modtime` - Don't update Google Drive mod times
- Detailed logging to ~/Library/Logs/

---

## Monitoring & Maintenance

### Check Sync Status
```bash
# View recent sync activity
tail -50 ~/Library/Logs/icloud-gdrive-sync.log

# Check for errors
grep -i error ~/Library/Logs/icloud-gdrive-sync.log

# See current launchd status
launchctl list | grep icloud-gdrive
```

### Manual Sync
```bash
# Trigger immediate sync (don't wait for schedule)
launchctl start com.user.icloud-gdrive-sync

# Or run script directly
~/dotfiles/scripts/sync-icloud-to-gdrive.sh
```

### Adjust Frequency
Edit `~/Library/LaunchAgents/com.user.icloud-gdrive-sync.plist`:
- `21600` = 6 hours
- `43200` = 12 hours
- `86400` = 24 hours (daily)

After editing:
```bash
launchctl unload ~/Library/LaunchAgents/com.user.icloud-gdrive-sync.plist
launchctl load ~/Library/LaunchAgents/com.user.icloud-gdrive-sync.plist
```

---

## Benefits of This Approach

✅ **No Conflict with iCloud**
- iCloud remains the primary system
- Google Drive is backup only (one-way)
- No competing sync agents modifying same files

✅ **Works with iCloud's Eviction**
- Only syncs files actually downloaded locally
- Skips .icloud placeholder files automatically

✅ **Efficient**
- Incremental sync (only changed files)
- Runs in background without user interaction
- Minimal performance impact

✅ **Safe**
- Detailed logging of all operations
- No deletions from source (iCloud)
- All data preserved in both locations

✅ **Automated**
- Runs every 6 hours automatically
- Starts on system boot
- Recovers from sleep/power events

---

## Alternative: Using MultCloud (Cloud-to-Cloud)

If you prefer a GUI solution without local syncing:

**Service:** [MultCloud](https://www.multcloud.com/tutorials/sync-google-drive-with-icloud-5555-gc.html)

**Pros:**
- No local resources used
- Direct cloud-to-cloud sync
- GUI interface
- Real-time sync option

**Cons:**
- Third-party service (security/privacy considerations)
- Free tier limits (may need paid plan)
- Dependent on external service availability

---

## Next Steps

1. ⏳ Install rclone (via Homebrew or add to Nix config)
2. ⏳ Configure rclone with Google Drive OAuth
3. ⏳ Create sync script in dotfiles
4. ⏳ Create launchd plist
5. ⏳ Test manual sync
6. ⏳ Load launchd agent for automatic sync
7. ⏳ Monitor first few syncs for errors

---

## Sources

Research based on:
- [iCloud Desktop & Documents - Apple Support](https://support.apple.com/en-us/109344)
- [Sync iCloud with Google Drive - MultCloud](https://www.multcloud.com/tutorials/sync-icloud-with-google-drive-1003.html)
- [Using rclone and launchd on MacOS - DEV Community](https://dev.to/dunkbing/using-rclone-and-launchd-to-sync-data-to-google-drive-on-macos-150j)
- [MacOS Rsync iCloud To Linux - GitHub](https://github.com/DartSteven/MacOS-Rsync-iCloud-To-Linux)
- [Backing up iCloud Drive using rsync - Jesse Squires](https://www.jessesquires.com/blog/2019/09/27/icloud-backup-using-rsync/)
- [Rclone Official Documentation](https://rclone.org/)

---

**Status:** ✅ Research complete, implementation plan ready
**Recommended:** Implement rclone + launchd approach for automated, reliable sync
