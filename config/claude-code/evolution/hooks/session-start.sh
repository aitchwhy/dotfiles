#!/usr/bin/env bash
# Session Start Hook - Loads lessons and warns if metrics are stale
# Returns JSON with additionalContext for Claude
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
METRICS="$DOTFILES/.claude-metrics/latest.json"
LESSONS="$DOTFILES/config/claude-code/evolution/lessons/lessons.jsonl"

OUTPUT=""

# Check if metrics exist and are stale (>24h)
if [[ -f "$METRICS" ]]; then
    # Get file modification time in epoch seconds
    if [[ "$(uname)" == "Darwin" ]]; then
        MTIME=$(date -r "$METRICS" +%s 2>/dev/null || echo 0)
    else
        MTIME=$(stat -c %Y "$METRICS" 2>/dev/null || echo 0)
    fi

    AGE=$(( ($(date +%s) - MTIME) / 3600 ))
    SCORE=$(jq -r '.overall_score * 100 | floor' "$METRICS" 2>/dev/null || echo "?")
    REC=$(jq -r '.recommendation' "$METRICS" 2>/dev/null || echo "unknown")

    if [[ $AGE -gt 24 ]]; then
        OUTPUT+="🧬 Evolution: ${SCORE}% (${REC}) - stale (${AGE}h). Run: just evolve\n"
    fi
fi

# Load recent lessons as context (last 5)
if [[ -f "$LESSONS" && -s "$LESSONS" ]]; then
    RECENT=$(tail -5 "$LESSONS" 2>/dev/null | jq -rs 'map(.lesson // empty) | join("; ")' 2>/dev/null || echo "")
    if [[ -n "$RECENT" && "$RECENT" != "null" ]]; then
        OUTPUT+="Recent lessons: $RECENT"
    fi
fi

# Output JSON for Claude to consume (if we have anything to say)
if [[ -n "$OUTPUT" ]]; then
    jq -n --arg ctx "$OUTPUT" '{additionalContext: $ctx}'
fi

exit 0
