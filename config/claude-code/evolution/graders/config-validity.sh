#!/usr/bin/env bash
# Config Validity Grader - Checks JSON/YAML parsing and symlinks
# Weight: 35% of overall score
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
SCORE=100
ISSUES=()

# JSON validation (5 pts per invalid file)
while IFS= read -r -d '' f; do
    if ! jq empty "$f" 2>/dev/null; then
        SCORE=$((SCORE - 5))
        ISSUES+=("invalid json: ${f##*/}")
    fi
done < <(find "$DOTFILES/config" -name "*.json" -print0 2>/dev/null)

# YAML validation (5 pts per invalid file)
while IFS= read -r -d '' f; do
    if ! yq '.' "$f" >/dev/null 2>&1; then
        SCORE=$((SCORE - 5))
        ISSUES+=("invalid yaml: ${f##*/}")
    fi
done < <(find "$DOTFILES/config" \( -name "*.yaml" -o -name "*.yml" \) -print0 2>/dev/null)

# Critical symlinks (10 pts each)
CRITICAL_LINKS=(
    "$HOME/.config/nvim"
    "$HOME/.zshrc"
    "$HOME/.config/starship.toml"
    "$HOME/.config/ghostty"
)

for link in "${CRITICAL_LINKS[@]}"; do
    if [[ ! -L "$link" ]] || [[ ! -e "$link" ]]; then
        SCORE=$((SCORE - 10))
        ISSUES+=("missing or broken: $link")
    fi
done

# Clamp score to 0-100
[[ $SCORE -lt 0 ]] && SCORE=0

# Output JSON result
ISSUES_JSON=$(printf '%s\n' "${ISSUES[@]}" 2>/dev/null | jq -R . | jq -s . || echo "[]")
jq -n --argjson score "$SCORE" --argjson issues "$ISSUES_JSON" \
    '{grader:"config-validity",score:($score/100),passed:($score>=75),issues:$issues}'
