#!/usr/bin/env bash
# Post-switch garbage collection hook
# Runs after darwin-rebuild switch to clean up old generations
# Triggered by PostToolUse hook on darwin-rebuild commands
set -euo pipefail

# Parse hook input from stdin
INPUT=$(cat)

# Check if this is a darwin-rebuild switch command
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")

# Only run after darwin-rebuild switch (not build)
if [[ "$TOOL_NAME" != "Bash" ]] || [[ "$COMMAND" != *"darwin-rebuild"*"switch"* ]]; then
    echo '{"continue": true}'
    exit 0
fi

# Check if the command succeeded (exit code 0)
RESULT=$(echo "$INPUT" | jq -r '.tool_result // empty' 2>/dev/null || echo "")
if [[ -z "$RESULT" ]] || [[ "$RESULT" == *"error"* ]] || [[ "$RESULT" == *"Error"* ]]; then
    echo '{"continue": true}'
    exit 0
fi

# Count generations
GEN_COUNT=$(darwin-rebuild --list-generations 2>/dev/null | wc -l | tr -d ' ' || echo "0")

# Only run GC if we have more than 10 generations
if [[ "$GEN_COUNT" -gt 10 ]]; then
    # Run GC in background to not block the agent
    (
        LOG_FILE="${HOME}/.claude-metrics/gc.log"
        mkdir -p "$(dirname "$LOG_FILE")"

        echo "[$(date -Iseconds)] Starting auto-GC (${GEN_COUNT} generations)" >> "$LOG_FILE"

        # Garbage collect old generations
        sudo nix-collect-garbage --delete-older-than 7d >> "$LOG_FILE" 2>&1 || true

        # Optimize store (hardlink duplicates)
        nix store optimise >> "$LOG_FILE" 2>&1 || true

        # Count new generations
        NEW_COUNT=$(darwin-rebuild --list-generations 2>/dev/null | wc -l | tr -d ' ' || echo "?")
        echo "[$(date -Iseconds)] Auto-GC complete (${GEN_COUNT} → ${NEW_COUNT} generations)" >> "$LOG_FILE"
    ) &

    disown
fi

# Always continue - don't block the agent
echo '{"continue": true}'
