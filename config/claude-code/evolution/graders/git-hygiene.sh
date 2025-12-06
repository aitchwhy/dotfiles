#!/usr/bin/env bash
# Git Hygiene Grader - Checks commits, secrets, and .gitignore
# Weight: 25% of overall score
set -euo pipefail

cd "${DOTFILES:-$HOME/dotfiles}"
SCORE=100
ISSUES=()

# Unstaged changes (30 pts if > 10 files)
UNSTAGED=$(git diff --name-only | wc -l | tr -d ' ')
if [[ "$UNSTAGED" -gt 10 ]]; then
    SCORE=$((SCORE - 30))
    ISSUES+=("$UNSTAGED unstaged changes")
fi

# Conventional commits (25 pts) - Check last 10 commits
REGEX="^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?!?:"
BAD=0
while IFS= read -r msg; do
    if [[ -n "$msg" && ! "$msg" =~ $REGEX ]]; then
        BAD=$((BAD + 1))
    fi
done <<< "$(git log --oneline -10 --format='%s')"

if [[ "$BAD" -gt 3 ]]; then
    SCORE=$((SCORE - 25))
    ISSUES+=("$BAD of last 10 commits non-conventional")
fi

# Secrets scan (35 pts - critical security issue)
# Look for actual secret values, not just pattern names in config
# Exclude: shell scripts that reference env vars, example files, graders themselves
SECRET_FOUND=false
if git grep -qE 'ANTHROPIC_API_KEY\s*=' -- ':!*.sh' ':!*.example' ':!*graders*' 2>/dev/null; then
    # Check if it's an actual assignment with a value (not just checking if set)
    if git grep -E 'ANTHROPIC_API_KEY\s*=\s*[^${\n]' -- ':!*.sh' ':!*.example' ':!*graders*' 2>/dev/null | grep -qv '=\s*$'; then
        SECRET_FOUND=true
        ISSUES+=("potential secret: ANTHROPIC_API_KEY assignment")
    fi
fi

# Check for actual API key patterns (the values, not variable names)
DANGEROUS_PATTERNS=(
    'sk-[a-zA-Z0-9]{20,}'           # OpenAI keys
    'ghp_[a-zA-Z0-9]{36}'           # GitHub personal access tokens
    'gho_[a-zA-Z0-9]{36}'           # GitHub OAuth tokens
    '-----BEGIN.*PRIVATE KEY-----'   # Private keys
)

for p in "${DANGEROUS_PATTERNS[@]}"; do
    if git grep -qE "$p" -- ':!*.gpg' ':!*.example' 2>/dev/null; then
        SECRET_FOUND=true
        ISSUES+=("potential secret pattern found")
        break
    fi
done

if [[ "$SECRET_FOUND" == true ]]; then
    SCORE=$((SCORE - 35))
fi

# .gitignore coverage (10 pts)
REQUIRED_IGNORES=(".env" ".envrc" "*.gpg" ".dev.vars")
for pat in "${REQUIRED_IGNORES[@]}"; do
    if ! grep -qF "$pat" .gitignore 2>/dev/null; then
        SCORE=$((SCORE - 3))
        ISSUES+=("missing gitignore: $pat")
    fi
done

# Clamp score to 0-100
[[ $SCORE -lt 0 ]] && SCORE=0

# Output JSON result
ISSUES_JSON=$(printf '%s\n' "${ISSUES[@]}" 2>/dev/null | jq -R . | jq -s . || echo "[]")
jq -n --argjson score "$SCORE" --argjson issues "$ISSUES_JSON" \
    '{grader:"git-hygiene",score:($score/100),passed:($score>=70),issues:$issues}'
