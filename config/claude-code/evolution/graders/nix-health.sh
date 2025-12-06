#!/usr/bin/env bash
# Nix Health Grader - Checks flake validity, formatting, and patterns
# Weight: 40% of overall score
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
SCORE=100
ISSUES=()

# Flake check (40 pts) - Does the flake evaluate without errors?
if ! nix flake check "$DOTFILES" --no-build 2>/dev/null; then
    SCORE=$((SCORE - 40))
    ISSUES+=("flake check failed")
fi

# Flake evaluates (30 pts) - Can we build the system config?
if ! nix eval "$DOTFILES#darwinConfigurations.$(hostname -s).system" --json >/dev/null 2>&1; then
    SCORE=$((SCORE - 30))
    ISSUES+=("flake eval failed")
fi

# Nix fmt (15 pts) - Is the code formatted correctly?
if ! nix fmt "$DOTFILES" -- --check 2>/dev/null; then
    SCORE=$((SCORE - 15))
    ISSUES+=("needs nix fmt")
fi

# Deprecated patterns (15 pts) - Avoid 'with lib;' anti-pattern
DEP=$(grep -r "with lib;" "$DOTFILES"/*.nix "$DOTFILES"/modules/ 2>/dev/null | wc -l | tr -d ' ' || echo 0)
if [[ "$DEP" -gt 5 ]]; then
    SCORE=$((SCORE - 15))
    ISSUES+=("$DEP deprecated 'with lib;' patterns")
fi

# Clamp score to 0-100
[[ $SCORE -lt 0 ]] && SCORE=0

# Output JSON result
ISSUES_JSON=$(printf '%s\n' "${ISSUES[@]}" 2>/dev/null | jq -R . | jq -s . || echo "[]")
jq -n --argjson score "$SCORE" --argjson issues "$ISSUES_JSON" \
    '{grader:"nix-health",score:($score/100),passed:($score>=75),issues:$issues}'
