#!/usr/bin/env bash
# Plans Cleanup Hook - Purges plan files older than 3 days
# Runs on SessionStart to prevent accumulation of stale plans
# Uses modern CLI tools: fd
set -euo pipefail

PLANS_DIR="$HOME/.claude/plans"
MAX_AGE_DAYS=7

# Skip if plans directory doesn't exist
if [[ ! -d "$PLANS_DIR" ]]; then
    echo '{"continue": true}'
    exit 0
fi

# Find and delete plan files older than MAX_AGE_DAYS
# Using fd with --changed-before for cleaner syntax
DELETED_COUNT=0

# fd --changed-before NDd finds files not modified in last N days
for file in $(fd -t f -e md --changed-before "${MAX_AGE_DAYS}d" . "$PLANS_DIR" 2>/dev/null || true); do
    rm -f "$file" 2>/dev/null && ((DELETED_COUNT++)) || true
done

# Report cleanup if any files were deleted
if [[ $DELETED_COUNT -gt 0 ]]; then
    jq -n --arg ctx "Cleaned up $DELETED_COUNT stale plan file(s) older than ${MAX_AGE_DAYS} days" \
        '{continue: true, additionalContext: $ctx}'
else
    echo '{"continue": true}'
fi

exit 0
