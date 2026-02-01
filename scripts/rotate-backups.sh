#!/bin/bash
set -euo pipefail

GDRIVE_ROOT="/Users/hank/Library/CloudStorage/GoogleDrive-hank.lee.qed@gmail.com/My Drive/My Drive"
BACKUPS_DIR="$GDRIVE_ROOT/Backups"
ARCHIVE_DIR="$GDRIVE_ROOT/Backups/Auto-Rotation/Archived"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log "Starting backup rotation..."

# Rotate Anthropic backups: Keep latest 5
cd "$BACKUPS_DIR/Anthropic-Claude-AI"
backup_count=$(ls -t *.zip 2>/dev/null | wc -l | tr -d ' ')

if [ "$backup_count" -gt 5 ]; then
    log "Found $backup_count Anthropic backups, archiving older ones..."
    ls -t *.zip 2>/dev/null | tail -n +6 | while read backup; do
        log "Archiving: $backup"
        mv "$backup" "$ARCHIVE_DIR/"
    done
    log "Archived $((backup_count - 5)) backups"
else
    log "Only $backup_count Anthropic backups found, no archiving needed"
fi

# Clean up very old archived backups (older than 180 days)
log "Checking for archived backups older than 180 days..."
find "$ARCHIVE_DIR" -name "*.zip" -type f -mtime +180 -print | while read old_backup; do
    log "Removing old archived backup: $(basename "$old_backup")"
    rm "$old_backup"
done

log "Backup rotation complete"
