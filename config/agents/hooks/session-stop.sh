#!/usr/bin/env bash
# Session Stop Hook - Extracts learnings and triggers consolidation
# Runs when Claude session ends
# Input: JSON with transcript_path from Claude Code Stop hook
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
METRICS="$HOME/.claude-metrics"
GRADE_SCRIPT="$DOTFILES/config/agents/evolution/grade.sh"
TREND_ALERT="$DOTFILES/config/agents/evolution/trend-alert.sh"
LESSON_WRITER="$DOTFILES/config/agents/hooks/lesson-writer.ts"
CONSOLIDATE="$DOTFILES/config/agents/evolution/consolidate.ts"

mkdir -p "$METRICS"

# Parse JSON input from stdin
INPUT=""
if ! [ -t 0 ]; then
  INPUT=$(cat)
fi

# Extract transcript_path from hook input
TRANSCRIPT_PATH=""
if [[ -n "$INPUT" ]]; then
  TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || true)
fi

# Fallback: find recent session files if no transcript_path provided
if [[ -z "$TRANSCRIPT_PATH" || ! -f "$TRANSCRIPT_PATH" ]]; then
  SESSION_DIRS=(
    "$HOME/.claude/projects"
    "$HOME/.claude/sessions"
  )

  for dir in "${SESSION_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
      # Find most recently modified .jsonl file in last 10 minutes
      FOUND=$(find "$dir" -name "*.jsonl" -mmin -10 -type f 2>/dev/null | head -1)
      if [[ -n "$FOUND" ]]; then
        TRANSCRIPT_PATH="$FOUND"
        break
      fi
    fi
  done
fi

# Extract lessons from transcript
if [[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]]; then
  # Pass transcript path to lesson-writer
  bun run "$LESSON_WRITER" "$TRANSCRIPT_PATH" 2>/dev/null || true
fi

# Run consolidation (dedup, decay, archive, git dump)
if [[ -x "$CONSOLIDATE" || -f "$CONSOLIDATE" ]]; then
  bun run "$CONSOLIDATE" >/dev/null 2>&1 || true
fi

# Trigger grading and trend analysis in background (non-blocking)
if [[ -x "$GRADE_SCRIPT" ]]; then
  (
    "$GRADE_SCRIPT" > "$METRICS/last-grade.log" 2>&1
    # Run trend analysis after grading completes
    if [[ -x "$TREND_ALERT" ]]; then
      "$TREND_ALERT" >> "$METRICS/last-grade.log" 2>&1
    fi
  ) &
fi

# Output valid JSON for Claude Code
echo '{"continue": true}'
exit 0
