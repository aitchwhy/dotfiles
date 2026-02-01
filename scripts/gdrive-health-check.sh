#!/bin/bash
set -euo pipefail

GDRIVE_ROOT="/Users/hank/Library/CloudStorage/GoogleDrive-hank.lee.qed@gmail.com/My Drive/My Drive"
LOST_FOUND="/Users/hank/Library/Application Support/Google/DriveFS/lost_and_found"

echo "=== Google Drive Health Check ==="
echo "Date: $(date)"
echo ""

# Check if Google Drive is running
if ! pgrep -x "Google Drive" > /dev/null; then
    echo "⚠️  WARNING: Google Drive is not running!"
    exit 1
fi

echo "✅ Google Drive is running"

# Check lost_and_found
if [ -d "$LOST_FOUND" ] && [ "$(ls -A "$LOST_FOUND" 2>/dev/null)" ]; then
    echo "⚠️  WARNING: Files in lost_and_found directory!"
    du -sh "$LOST_FOUND"/*/ 2>/dev/null || true
    exit 1
fi

echo "✅ No files in lost_and_found"

# Report sizes
echo ""
echo "=== Storage Report ==="
echo "Google Drive size: $(du -sh "$GDRIVE_ROOT" 2>/dev/null | cut -f1 || echo "Unable to calculate")"
echo "Desktop size: $(du -sh ~/Desktop 2>/dev/null | cut -f1 || echo "Unable to calculate")"
echo "Movies size: $(du -sh ~/Movies 2>/dev/null | cut -f1 || echo "Unable to calculate")"
echo "Downloads size: $(du -sh ~/Downloads 2>/dev/null | cut -f1 || echo "Unable to calculate")"

# Count Google Drive root items
root_items=$(ls -1 "$GDRIVE_ROOT" 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo "=== Organization Report ==="
echo "Google Drive root items: $root_items"

if [ "$root_items" -gt 50 ]; then
    echo "⚠️  WARNING: More than 50 items in root (target: <50)"
else
    echo "✅ Root organization looks good"
fi

# Check Anthropic backups
anthropic_backups=$(ls -1 "$GDRIVE_ROOT/Backups/Anthropic-Claude-AI/"*.zip 2>/dev/null | wc -l | tr -d ' ')
echo "Anthropic backups in main folder: $anthropic_backups"

if [ "$anthropic_backups" -gt 5 ]; then
    echo "⚠️  WARNING: More than 5 Anthropic backups (rotation needed)"
elif [ "$anthropic_backups" -lt 1 ]; then
    echo "⚠️  WARNING: No Anthropic backups found"
else
    echo "✅ Backup count looks good"
fi

echo ""
echo "=== Health Check Complete ==="
exit 0
