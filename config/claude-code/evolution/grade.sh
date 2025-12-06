#!/usr/bin/env bash
# Grade Orchestrator - Runs all graders and computes weighted score
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
METRICS="$DOTFILES/.claude-metrics"
mkdir -p "$METRICS"

# Grader weights (must sum to 100)
declare -A WEIGHTS=(
    ["nix-health"]=40
    ["config-validity"]=35
    ["git-hygiene"]=25
)

TOTAL=0
RESULTS=()

for grader in nix-health config-validity git-hygiene; do
    GRADER_SCRIPT="$SCRIPT_DIR/graders/$grader.sh"

    if [[ -x "$GRADER_SCRIPT" ]]; then
        RESULT=$("$GRADER_SCRIPT" 2>/dev/null || echo "{\"grader\":\"$grader\",\"score\":0,\"passed\":false,\"issues\":[\"grader error\"]}")
    else
        RESULT="{\"grader\":\"$grader\",\"score\":0,\"passed\":false,\"issues\":[\"grader not found\"]}"
    fi

    SCORE=$(echo "$RESULT" | jq -r '.score // 0')
    WEIGHT=${WEIGHTS[$grader]}
    WEIGHTED=$(echo "scale=4; $SCORE * $WEIGHT" | bc)
    TOTAL=$(echo "scale=4; $TOTAL + $WEIGHTED" | bc)
    RESULTS+=("$RESULT")
done

# Calculate final score (0-1 scale)
FINAL=$(echo "scale=4; $TOTAL / 100" | bc)

# Determine recommendation
if [[ $(echo "$FINAL >= 0.9" | bc) -eq 1 ]]; then
    RECOMMENDATION="stable"
elif [[ $(echo "$FINAL >= 0.7" | bc) -eq 1 ]]; then
    RECOMMENDATION="improve"
else
    RECOMMENDATION="urgent"
fi

# Build final JSON
GRADERS_JSON=$(printf '%s\n' "${RESULTS[@]}" | jq -s '.')
FINAL_JSON=$(jq -n \
    --argjson score "$FINAL" \
    --arg rec "$RECOMMENDATION" \
    --argjson graders "$GRADERS_JSON" \
    '{
        timestamp: (now | todate),
        overall_score: $score,
        recommendation: $rec,
        graders: $graders
    }')

# Write to metrics (pretty for latest.json, compact for history.jsonl)
echo "$FINAL_JSON" > "$METRICS/latest.json"
echo "$FINAL_JSON" | jq -c '.' >> "$METRICS/history.jsonl"

# Output result (pretty for human readability)
echo "$FINAL_JSON"
