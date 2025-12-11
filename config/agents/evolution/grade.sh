#!/usr/bin/env bash
# grade.sh - Evolution system health grader
# Outputs JSON: {overall_score: 0-1, recommendation: "ok"|"warning"|"urgent", details: {...}}
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
SIGNET_DIR="$DOTFILES/config/signet"
AGENTS_DIR="$DOTFILES/config/agents"

# Initialize scores and details
declare -a SCORES=()
declare -a WEIGHTS=()
declare DETAILS_JSON="{}"

# Helper to add a check result
add_result() {
  local name="$1"
  local score="$2"
  local weight="$3"
  local detail_json="$4"

  SCORES+=("$score")
  WEIGHTS+=("$weight")
  DETAILS_JSON=$(echo "$DETAILS_JSON" | jq --arg name "$name" --argjson detail "$detail_json" '. + {($name): $detail}')
}

# Check 1: Nix Flake Validity (25%)
check_nix_flake() {
  local score=100
  local message="ok"

  if [[ ! -f "$DOTFILES/flake.nix" ]]; then
    score=0
    message="flake.nix missing"
  elif ! nix flake check "$DOTFILES" --no-build 2>/dev/null; then
    score=50
    message="flake check failed"
  fi

  add_result "nix_flake" "$score" 25 "{\"score\":$score,\"message\":\"$message\"}"
}

# Check 2: TypeScript Type Checking (20%)
check_typescript() {
  local score=100
  local message="ok"

  if [[ ! -d "$SIGNET_DIR" ]]; then
    score=0
    message="signet directory missing"
  elif [[ ! -f "$SIGNET_DIR/package.json" ]]; then
    score=50
    message="package.json missing"
  else
    pushd "$SIGNET_DIR" >/dev/null
    if ! bun run typecheck >/dev/null 2>&1; then
      score=30
      message="type errors detected"
    fi
    popd >/dev/null
  fi

  add_result "typescript" "$score" 20 "{\"score\":$score,\"message\":\"$message\"}"
}

# Check 3: Hook Health (20%)
check_hooks() {
  local score=100
  local missing=0
  local total=0

  local hooks=(
    "unified-guard.ts"
    "unified-polish.ts"
    "enforce-versions.ts"
    "stack-enforcer.ts"
    "devops-enforcer.ts"
    "auto-migrate.ts"
    "verification-gate.ts"
    "validate-flake.ts"
  )

  for hook in "${hooks[@]}"; do
    total=$((total + 1))
    if [[ ! -f "$AGENTS_DIR/hooks/$hook" ]]; then
      missing=$((missing + 1))
    fi
  done

  if [[ $total -gt 0 ]]; then
    score=$(( (total - missing) * 100 / total ))
  fi

  add_result "hooks" "$score" 20 "{\"score\":$score,\"missing\":$missing,\"total\":$total}"
}

# Check 4: Skills Integrity (15%)
check_skills() {
  local score=100
  local missing_md=0
  local total_skills=0

  if [[ -d "$AGENTS_DIR/skills" ]]; then
    for skill in "$AGENTS_DIR/skills"/*/; do
      if [[ -d "$skill" ]]; then
        total_skills=$((total_skills + 1))
        if [[ ! -f "$skill/SKILL.md" ]]; then
          missing_md=$((missing_md + 1))
        fi
      fi
    done
  fi

  if [[ $total_skills -gt 0 && $missing_md -gt 0 ]]; then
    score=$((100 - missing_md * 10))
    [[ $score -lt 0 ]] && score=0
  fi

  add_result "skills" "$score" 15 "{\"score\":$score,\"missing_md\":$missing_md,\"total\":$total_skills}"
}

# Check 5: Version Alignment (20%)
check_versions() {
  local score=100
  local message="ok"

  local versions_ts="$SIGNET_DIR/src/stack/versions.ts"
  local versions_json="$SIGNET_DIR/versions.json"

  if [[ ! -f "$versions_ts" ]]; then
    score=0
    message="versions.ts missing (SSOT)"
  elif [[ -f "$versions_json" ]]; then
    # Extract ssotVersion from both files
    local ts_version json_version
    ts_version=$(grep -oP "ssotVersion['\"]?\s*[:=]\s*['\"]?\K[0-9]+\.[0-9]+\.[0-9]+" "$versions_ts" 2>/dev/null | head -1 || echo "")
    json_version=$(jq -r '.meta.ssotVersion // empty' "$versions_json" 2>/dev/null || echo "")

    if [[ -n "$ts_version" && -n "$json_version" && "$ts_version" != "$json_version" ]]; then
      score=70
      message="SSOT version mismatch: ts=$ts_version, json=$json_version"
    fi
  fi

  add_result "versions" "$score" 20 "{\"score\":$score,\"message\":\"$message\"}"
}

# Calculate weighted overall score
calculate_overall() {
  local weighted_sum=0
  local total_weight=0

  for i in "${!SCORES[@]}"; do
    weighted_sum=$((weighted_sum + SCORES[i] * WEIGHTS[i]))
    total_weight=$((total_weight + WEIGHTS[i]))
  done

  if [[ $total_weight -gt 0 ]]; then
    # Calculate as decimal (0-1)
    echo "scale=2; $weighted_sum / $total_weight / 100" | bc
  else
    echo "0.00"
  fi
}

# Determine recommendation based on score
get_recommendation() {
  local score="$1"
  local score_int

  # Convert 0.XX to integer XX
  score_int=$(echo "$score * 100" | bc | cut -d. -f1)
  score_int=${score_int:-0}

  if [[ $score_int -lt 50 ]]; then
    echo "urgent"
  elif [[ $score_int -lt 80 ]]; then
    echo "warning"
  else
    echo "ok"
  fi
}

# Main execution
main() {
  # Run all checks
  check_nix_flake
  check_typescript
  check_hooks
  check_skills
  check_versions

  # Calculate results
  local overall_score recommendation timestamp
  overall_score=$(calculate_overall)
  recommendation=$(get_recommendation "$overall_score")
  timestamp=$(date -Iseconds)

  # Output final JSON
  jq -n \
    --arg score "$overall_score" \
    --arg rec "$recommendation" \
    --arg ts "$timestamp" \
    --argjson details "$DETAILS_JSON" \
    '{
      overall_score: ($score | tonumber),
      recommendation: $rec,
      timestamp: $ts,
      details: $details
    }'
}

main
