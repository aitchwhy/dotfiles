#!/usr/bin/env bash
# Session Stop Hook - Extracts learnings and triggers background grading
# Runs when Claude session ends
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
LESSONS="$DOTFILES/config/claude-code/evolution/lessons/lessons.jsonl"
METRICS="$DOTFILES/.claude-metrics"
GRADE_SCRIPT="$DOTFILES/config/claude-code/evolution/grade.sh"

mkdir -p "$(dirname "$LESSONS")" "$METRICS"

# Try to find session transcripts (fallback gracefully if not found)
# Claude Code stores sessions in ~/.claude/projects/<project-hash>/
SESSION_DIRS=(
    "$HOME/.claude/projects"
    "$HOME/.claude/sessions"
)

LATEST_SESSION=""
for dir in "${SESSION_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        # Find most recently modified .jsonl file in last 10 minutes
        FOUND=$(find "$dir" -name "*.jsonl" -mmin -10 -type f 2>/dev/null | head -1)
        if [[ -n "$FOUND" ]]; then
            LATEST_SESSION="$FOUND"
            break
        fi
    fi
done

# Extract insights if we found a session
if [[ -n "$LATEST_SESSION" && -f "$LATEST_SESSION" ]]; then
    # Look for patterns that indicate lessons/insights
    PATTERNS="lesson|learned|remember|important|always|never|mistake|insight|note to self"

    # Extract text from assistant messages, then filter for insight patterns
    # FIX: jq first to extract text from valid JSONL, then grep for patterns
    INSIGHTS=$(jq -r 'select(.type == "assistant") | .message.content // empty' "$LATEST_SESSION" 2>/dev/null |
        grep -iE "$PATTERNS" |
        head -3 || echo "")

    # Save any insights found
    if [[ -n "$INSIGHTS" ]]; then
        while IFS= read -r insight; do
            if [[ -n "$insight" && ${#insight} -gt 10 ]]; then
                jq -n --arg l "$insight" '{timestamp:(now|todate),lesson:$l,source:"session"}' >> "$LESSONS"
            fi
        done <<< "$INSIGHTS"
    fi
fi

# Trigger graders in background (non-blocking)
if [[ -x "$GRADE_SCRIPT" ]]; then
    nohup "$GRADE_SCRIPT" > "$METRICS/last-grade.log" 2>&1 &
fi

exit 0
