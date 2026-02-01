#!/bin/bash
# Check for duplicate same-day backups and keep only the latest

backup_file="$1"
backup_dir=$(dirname "$backup_file")
backup_name=$(basename "$backup_file")

# Extract date from filename (assumes format: *-YYYY-MM-DD*)
date_pattern=$(echo "$backup_name" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')

if [ -n "$date_pattern" ]; then
    # Find all backups with same date
    same_date_backups=$(find "$backup_dir" -name "*$date_pattern*" -type f | sort)
    backup_count=$(echo "$same_date_backups" | wc -l | tr -d ' ')

    if [ "$backup_count" -gt 1 ]; then
        echo "Found $backup_count backups for date $date_pattern"
        # Keep only the latest (last in sorted list)
        echo "$same_date_backups" | head -n -1 | while read old_backup; do
            echo "Moving duplicate to trash: $old_backup"
            mv "$old_backup" ~/.Trash/
        done
    fi
fi
