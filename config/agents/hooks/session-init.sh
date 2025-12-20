#!/usr/bin/env bash
# Session Init Hook - Consolidated SessionStart hook
# Combines: session logging, plans cleanup, evolution metrics
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
PLANS_DIR="$HOME/.claude/plans"
MAX_AGE_DAYS=7
LOG_FILE="$HOME/.claude/session.log"

OUTPUT=""

# 1. Log session start
mkdir -p "$(dirname "$LOG_FILE")"
echo "[$(date -Iseconds)] Session started: $(pwd)" >> "$LOG_FILE"

# 2. Clean old plan files (>7 days)
if [[ -d "$PLANS_DIR" ]]; then
    DELETED_COUNT=0
    for file in $(fd -t f -e md --changed-before "${MAX_AGE_DAYS}d" . "$PLANS_DIR" 2>/dev/null || true); do
        rm -f "$file" 2>/dev/null && ((DELETED_COUNT++)) || true
    done
    if [[ $DELETED_COUNT -gt 0 ]]; then
        OUTPUT+="Cleaned $DELETED_COUNT stale plan(s). "
    fi
fi

# 3. Environment warnings (non-blocking)
if [[ -f "flake.nix" && -z "${IN_NIX_SHELL:-}" ]]; then
    OUTPUT+="⚠️ Nix project - consider nix develop. "
fi

if [[ -f "package-lock.json" ]]; then
    OUTPUT+="⚠️ package-lock.json found - use pnpm. "
fi

if [[ -f ".env" && ! -f ".env.example" ]]; then
    OUTPUT+="⚠️ .env without .env.example. "
fi

# 4. Evolution metrics (if available)
METRICS="$DOTFILES/.claude-metrics/latest.json"
if [[ -f "$METRICS" ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
        MTIME=$(date -r "$METRICS" +%s 2>/dev/null || echo 0)
    else
        MTIME=$(stat -c %Y "$METRICS" 2>/dev/null || echo 0)
    fi

    AGE=$(( ($(date +%s) - MTIME) / 3600 ))
    SCORE=$(jq -r '.overall_score * 100 | floor' "$METRICS" 2>/dev/null || echo "?")
    REC=$(jq -r '.recommendation' "$METRICS" 2>/dev/null || echo "unknown")

    if [[ $AGE -gt 24 ]]; then
        OUTPUT+="🧬 Evolution: ${SCORE}% (${REC}) - stale (${AGE}h). Run: just evolve. "
    fi
fi

# Output JSON for Claude to consume
if [[ -n "$OUTPUT" ]]; then
    jq -n --arg ctx "$OUTPUT" '{continue: true, additionalContext: $ctx}'
else
    echo '{"continue": true}'
fi

exit 0
