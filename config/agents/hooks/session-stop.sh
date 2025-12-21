#!/usr/bin/env bash
# Session Stop Hook - Consolidated Stop handler
# Absorbs: inline logging, verification-gate call
# Calls: lesson-writer, consolidation, grade.sh
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
METRICS="$HOME/.claude-metrics"
LOG_FILE="$HOME/.claude/session.log"
VERIFY_GATE="$DOTFILES/config/agents/hooks/verification-gate.ts"
GRADE_SCRIPT="$DOTFILES/config/agents/evolution/grade.sh"
LESSON_WRITER="$DOTFILES/config/agents/hooks/lesson-writer.ts"
CONSOLIDATE="$DOTFILES/config/agents/evolution/consolidate.ts"

mkdir -p "$METRICS" "$(dirname "$LOG_FILE")"

# ============================================================================
# 1. Log session end (ABSORBED from inline echo hook)
# ============================================================================
FILES=$(git diff --name-only HEAD~5 2>/dev/null | wc -l | tr -d ' ' || echo "0")
COMMITS=$(git log --oneline --since='1 hour ago' 2>/dev/null | wc -l | tr -d ' ' || echo "0")
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Session ended | Dir: $(basename "$PWD") | Files: $FILES modified | Commits: $COMMITS" >> "$LOG_FILE"

# ============================================================================
# 2. Parse JSON input for transcript_path
# ============================================================================
INPUT=""
if ! [ -t 0 ]; then
  INPUT=$(cat)
fi

TRANSCRIPT_PATH=""
if [[ -n "$INPUT" ]]; then
  TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || true)
fi

# Fallback: find recent session files
if [[ -z "$TRANSCRIPT_PATH" || ! -f "$TRANSCRIPT_PATH" ]]; then
  SESSION_DIRS=("$HOME/.claude/projects" "$HOME/.claude/sessions")
  for dir in "${SESSION_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
      FOUND=$(fd -t f -e jsonl --changed-within 10m . "$dir" 2>/dev/null | head -1)
      if [[ -n "$FOUND" ]]; then
        TRANSCRIPT_PATH="$FOUND"
        break
      fi
    fi
  done
fi

# ============================================================================
# 3. Extract lessons (best-effort)
# ============================================================================
if [[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" && -f "$LESSON_WRITER" ]]; then
  bun run "$LESSON_WRITER" "$TRANSCRIPT_PATH" 2>/dev/null || true
fi

# ============================================================================
# 4. Run consolidation (best-effort)
# ============================================================================
if [[ -f "$CONSOLIDATE" ]]; then
  bun run "$CONSOLIDATE" >/dev/null 2>&1 || true
fi

# ============================================================================
# 5. Verification gate (BLOCKING - exit 2 on failure)
# ============================================================================
if [[ -f "$VERIFY_GATE" ]]; then
  # Pass through stdin to verification gate
  GATE_RESULT=$(echo "$INPUT" | bun run "$VERIFY_GATE" 2>&1) || GATE_EXIT=$?
  GATE_EXIT=${GATE_EXIT:-0}

  if [[ $GATE_EXIT -eq 2 ]]; then
    # Verification gate blocked - propagate failure
    echo "$GATE_RESULT"
    exit 2
  fi
fi

# ============================================================================
# 6. Grading (background, non-blocking)
# ============================================================================
if [[ -x "$GRADE_SCRIPT" ]]; then
  ("$GRADE_SCRIPT" > "$METRICS/last-grade.log" 2>&1) &
fi

# ============================================================================
# 7. Success output
# ============================================================================
echo '{"continue": true}'
exit 0
