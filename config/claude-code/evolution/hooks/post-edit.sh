#!/usr/bin/env bash
# Post-Edit Hook - Validates edited files and warns on issues (never blocks)
# Runs after existing formatting hooks
set -euo pipefail

# Read tool input from stdin
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)

# Exit gracefully if no file or file doesn't exist
[[ -z "$FILE" || ! -f "$FILE" ]] && exit 0

# Validate based on file type (warn only, never block)
case "$FILE" in
    *.json)
        if ! jq empty "$FILE" 2>/dev/null; then
            echo "⚠️ Evolution: Invalid JSON syntax in ${FILE##*/}" >&2
        fi
        ;;
    *.yaml|*.yml)
        if command -v yq >/dev/null 2>&1; then
            if ! yq '.' "$FILE" >/dev/null 2>&1; then
                echo "⚠️ Evolution: Invalid YAML syntax in ${FILE##*/}" >&2
            fi
        fi
        ;;
    *.nix)
        # Quick syntax check without full evaluation
        if command -v nix-instantiate >/dev/null 2>&1; then
            if ! nix-instantiate --parse "$FILE" >/dev/null 2>&1; then
                echo "⚠️ Evolution: Nix parse error in ${FILE##*/}" >&2
            fi
        fi
        ;;
esac

# Always exit 0 (never block edits, just warn)
exit 0
