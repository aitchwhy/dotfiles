#!/usr/bin/env bash
# Plans Cleanup Hook - Purges plan files older than 3 days
# Runs on SessionStart to prevent accumulation of stale plans
set -euo pipefail

PLANS_DIR="$HOME/.claude/plans"
MAX_AGE_DAYS=3

# Skip if plans directory doesn't exist
if [[ ! -d "$PLANS_DIR" ]]; then
    echo '{"continue": true}'
    exit 0
fi

# Find and delete plan files older than MAX_AGE_DAYS
# Using -mtime +N means "modified more than N days ago"
DELETED_COUNT=0
while IFS= read -r -d '' file; do
    rm -f "$file" 2>/dev/null && ((DELETED_COUNT++)) || true
done < <(command find "$PLANS_DIR" -maxdepth 1 -name "*.md" -type f -mtime +${MAX_AGE_DAYS} -print0 2>/dev/null)

# Report cleanup if any files were deleted
if [[ $DELETED_COUNT -gt 0 ]]; then
    jq -n --arg ctx "Cleaned up $DELETED_COUNT stale plan file(s) older than ${MAX_AGE_DAYS} days" \
        '{continue: true, additionalContext: $ctx}'
else
    echo '{"continue": true}'
fi

exit 0
