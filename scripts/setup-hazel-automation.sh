#!/bin/bash
# Automated Hazel Setup Script
# Configures Hazel to sync rules from dotfiles directory
# Uses AppleScript to automate GUI interactions

set -e

HAZEL_RULES_DIR="$HOME/dotfiles/config/hazel/rules"
HAZEL_APP="/Applications/Hazel.app"

echo "🔧 Setting up Hazel automation..."
echo ""

# Check if Hazel is installed
if [ ! -d "$HAZEL_APP" ]; then
    echo "❌ Error: Hazel.app not found at $HAZEL_APP"
    echo "Please ensure Hazel is installed via: brew install --cask hazel"
    exit 1
fi

# Check if rules directory exists
if [ ! -d "$HAZEL_RULES_DIR" ]; then
    echo "❌ Error: Rules directory not found: $HAZEL_RULES_DIR"
    exit 1
fi

echo "✓ Hazel installed: $HAZEL_APP"
echo "✓ Rules directory: $HAZEL_RULES_DIR"
echo ""

# Ensure Hazel is running
if ! pgrep -x "Hazel" > /dev/null; then
    echo "🚀 Starting Hazel..."
    open -a "Hazel"
    sleep 5
fi

echo "✓ Hazel is running"
echo ""

# Use AppleScript to configure folders and sync rules
osascript <<EOF
tell application "System Events"
    tell process "Hazel"
        -- Bring Hazel to front
        set frontmost to true
        delay 1

        -- Note: This requires manual setup in Hazel GUI for initial configuration
        -- The script will help organize the structure but folder addition needs GUI
    end tell
end tell
EOF

echo ""
echo "⚠️  MANUAL STEP REQUIRED:"
echo ""
echo "Hazel doesn't support fully automated CLI rule import."
echo "However, you can use the 'Sync Rules' feature:"
echo ""
echo "1. Open Hazel: Already running ✓"
echo ""
echo "2. For each folder, set up syncing:"
echo "   - Desktop: Sync to $HAZEL_RULES_DIR/desktop-critical.hazelrules"
echo "   - Downloads: Sync to $HAZEL_RULES_DIR/downloads-critical.hazelrules"
echo "   - Google Drive: Sync to $HAZEL_RULES_DIR/gdrive-critical.hazelrules"
echo "   - Backups: Sync to $HAZEL_RULES_DIR/backups-critical.hazelrules"
echo ""
echo "3. Once synced, Hazel will auto-update when files change in git!"
echo ""
echo "📚 Documentation: https://www.noodlesoft.com/manual/hazel/work-with-folders-rules/manage-rules/sync-rules/"
echo ""

# Create a helper file with the exact paths
cat > "$HOME/dotfiles/config/hazel/SYNC-PATHS.txt" <<PATHS
# Hazel Sync Paths
# Use these paths when setting up "Sync Rules" in Hazel

Desktop Rules:
$HAZEL_RULES_DIR/desktop-critical.hazelrules

Downloads Rules:
$HAZEL_RULES_DIR/downloads-critical.hazelrules

Google Drive Rules:
$HAZEL_RULES_DIR/gdrive-critical.hazelrules

Backups Rules:
$HAZEL_RULES_DIR/backups-critical.hazelrules
PATHS

echo "✅ Created sync paths reference: ~/dotfiles/config/hazel/SYNC-PATHS.txt"
echo ""
echo "Next: Follow the manual steps above to enable auto-sync from dotfiles"
