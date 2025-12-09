#!/usr/bin/env bash
# Reflection Engine - Analyzes issues and proposes improvements
# Hybrid: Uses Claude API when online, local heuristics when offline
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
METRICS="$DOTFILES/.claude-metrics/latest.json"
EVOLUTION_CLI="$DOTFILES/config/agents/evolution/src/index.ts"

# Check if metrics exist
if [[ ! -f "$METRICS" ]]; then
    echo "No metrics found. Run 'just evolve grade' first."
    exit 1
fi

EVAL=$(cat "$METRICS")
ISSUES=$(echo "$EVAL" | jq -r '.graders[].issues[]?' | sort -u)
SCORE=$(echo "$EVAL" | jq -r '.overall_score * 100 | floor')
REC=$(echo "$EVAL" | jq -r '.recommendation')

# Header
echo "═══════════════════════════════════════════════════════════════"
echo "                    EVOLUTION REFLECTION"
echo "═══════════════════════════════════════════════════════════════"
echo "Score: ${SCORE}% | Status: ${REC}"
echo ""

# No issues? We're done
if [[ -z "$ISSUES" ]]; then
    echo "✓ No issues found. Configuration healthy."
    exit 0
fi

echo "Issues found:"
echo "$ISSUES" | while read -r i; do
    [[ -n "$i" ]] && echo "  • $i"
done
echo ""

# Check for API availability
can_api() {
    [[ -n "${ANTHROPIC_API_KEY:-}" ]] &&
    curl -s --connect-timeout 2 https://api.anthropic.com >/dev/null 2>&1
}

if can_api; then
    echo "Mode: API (intelligent reflection)"
    echo ""

    # Build prompt for Claude
    PROMPT="You are analyzing a Nix-based dotfiles repository. Based on these issues, propose 1-3 minimal, actionable fixes.

Issues found:
$ISSUES

Current health score: ${SCORE}%

Respond with JSON only (no markdown):
{
  \"proposals\": [
    {\"action\": \"command or description\", \"rationale\": \"why this helps\"}
  ],
  \"lessons\": [\"insight to remember for future\"]
}"

    # Call Claude API
    RESP=$(curl -s https://api.anthropic.com/v1/messages \
        -H "Content-Type: application/json" \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -d "{
            \"model\": \"claude-sonnet-4-20250514\",
            \"max_tokens\": 1024,
            \"messages\": [{\"role\": \"user\", \"content\": $(echo "$PROMPT" | jq -Rs .)}]
        }" 2>/dev/null)

    # Extract JSON from response
    REFLECTION=$(echo "$RESP" | jq -r '.content[0].text // empty' 2>/dev/null | grep -o '{.*}' | head -1 || echo "{}")

    # Display proposals
    echo "Proposals:"
    echo "$REFLECTION" | jq -r '.proposals[]? | "  → \(.action)\n    (\(.rationale))"' 2>/dev/null || echo "  (could not parse API response)"
    echo ""

    # Save learned lessons to SQLite via CLI
    LEARNED=$(echo "$REFLECTION" | jq -r '.lessons[]?' 2>/dev/null)
    if [[ -n "$LEARNED" ]]; then
        echo "Lessons learned:"
        echo "$LEARNED" | while read -r l; do
            if [[ -n "$l" && "$l" != "null" ]]; then
                echo "  📝 $l"
                bun run "$EVOLUTION_CLI" lesson add "$l" --source reflection >/dev/null 2>&1 || true
            fi
        done
    fi
else
    echo "Mode: Local (heuristic proposals)"
    echo ""
    echo "Proposals:"

    # Local heuristics based on common issues (deduplicated)
    declare -A SEEN_PROPOSALS

    while read -r issue; do
        PROPOSAL=""
        # More specific patterns first, then general patterns
        case "$issue" in
            *"gitignore"*)
                PROPOSAL="Add missing patterns to .gitignore"
                ;;
            *"secret"*)
                PROPOSAL="URGENT: Remove secrets from tracked files, add to .gitignore"
                ;;
            *"fmt"*|*"format"*)
                PROPOSAL="Run: nix fmt ~/dotfiles"
                ;;
            *"deprecated"*|*"with lib"*)
                PROPOSAL="Refactor: Replace 'with lib;' with explicit imports (lib.mkIf, lib.mkDefault)"
                ;;
            *"unstaged"*|*"uncommit"*)
                PROPOSAL="Run: git add -p && git commit -m 'chore: stage pending changes'"
                ;;
            *"conventional"*)
                PROPOSAL="Use conventional format: feat:, fix:, docs:, refactor:, chore:"
                ;;
            *"invalid"*|*"Invalid"*)
                PROPOSAL="Fix: Validate JSON/YAML syntax with jq/yq"
                ;;
            *"missing"*|*"broken"*)
                PROPOSAL="Run: just switch (rebuild to fix symlinks)"
                ;;
            *"flake"*)
                PROPOSAL="Debug: nix flake check --show-trace"
                ;;
        esac

        # Only print if we have a proposal and haven't seen it before
        if [[ -n "$PROPOSAL" && -z "${SEEN_PROPOSALS[$PROPOSAL]:-}" ]]; then
            echo "  → $PROPOSAL"
            SEEN_PROPOSALS[$PROPOSAL]=1
        fi
    done <<< "$ISSUES"
fi

echo ""
echo "───────────────────────────────────────────────────────────────"
echo "To apply fixes: review proposals above and run in Claude Code"
echo "───────────────────────────────────────────────────────────────"
