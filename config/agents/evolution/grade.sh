#!/usr/bin/env bash
# grade.sh - Evolution system health grader with SQLite persistence
# Outputs JSON: {overall_score: 0-1, recommendation: "ok"|"warning"|"urgent", details: {...}}
# Uses modern CLI tools: rg (ripgrep)
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
QUALITY_DIR="$DOTFILES/config/quality"
AGENTS_DIR="$DOTFILES/config/agents"
METRICS_DIR="${HOME}/.claude-metrics"
DB_FILE="${METRICS_DIR}/evolution.db"

# Initialize scores and details
declare -a SCORES=()
declare -a WEIGHTS=()
declare DETAILS_JSON="{}"

# Initialize SQLite database if needed
init_db() {
  mkdir -p "$METRICS_DIR"

  if [[ ! -f "$DB_FILE" ]]; then
    sqlite3 "$DB_FILE" <<'EOF'
CREATE TABLE IF NOT EXISTS grades (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp TEXT NOT NULL,
  overall_score REAL NOT NULL,
  recommendation TEXT NOT NULL,
  details_json TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS trends (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL UNIQUE,
  avg_score REAL NOT NULL,
  min_score REAL NOT NULL,
  max_score REAL NOT NULL,
  check_count INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS lessons (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  category TEXT NOT NULL,
  lesson TEXT NOT NULL,
  evidence TEXT NOT NULL,
  source TEXT DEFAULT 'manual'
);

CREATE INDEX IF NOT EXISTS idx_grades_timestamp ON grades(timestamp);
CREATE INDEX IF NOT EXISTS idx_trends_date ON trends(date);
CREATE INDEX IF NOT EXISTS idx_lessons_category ON lessons(category);
EOF
  fi
}

# Store grade result in SQLite
store_grade() {
  local score="$1"
  local recommendation="$2"
  local timestamp="$3"
  local details="$4"

  # Escape single quotes in JSON for SQLite
  local escaped_details
  escaped_details=$(echo "$details" | sed "s/'/''/g")

  sqlite3 "$DB_FILE" "INSERT INTO grades (timestamp, overall_score, recommendation, details_json) VALUES ('$timestamp', $score, '$recommendation', '$escaped_details');"

  # Update daily trends
  local today
  today=$(date +%Y-%m-%d)

  sqlite3 "$DB_FILE" <<EOF
INSERT INTO trends (date, avg_score, min_score, max_score, check_count)
VALUES ('$today', $score, $score, $score, 1)
ON CONFLICT(date) DO UPDATE SET
  avg_score = (avg_score * check_count + $score) / (check_count + 1),
  min_score = MIN(min_score, $score),
  max_score = MAX(max_score, $score),
  check_count = check_count + 1;
EOF
}

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

# Check 1: Nix Flake Validity (20%)
check_nix_flake() {
  local score=100
  local message="ok"
  local has_derivation_split=false

  if [[ ! -f "$DOTFILES/flake.nix" ]]; then
    score=0
    message="flake.nix missing"
  elif ! nix flake check "$DOTFILES" --no-build 2>/dev/null; then
    score=50
    message="flake check failed"
  else
    # Check for derivation splitting pattern (using rg instead of grep)
    if rg -q "nodeModules" "$DOTFILES/flake.nix" 2>/dev/null || \
       rg -q "nodeModules" "$DOTFILES/flake/" 2>/dev/null; then
      has_derivation_split=true
    fi
  fi

  add_result "nix_flake" "$score" 20 "{\"score\":$score,\"message\":\"$message\",\"derivation_split\":$has_derivation_split}"
}

# Check 2: TypeScript Type Checking (20%)
check_typescript() {
  local score=100
  local message="ok"
  local any_count=0
  local zinfer_count=0

  if [[ ! -d "$QUALITY_DIR" ]]; then
    score=0
    message="quality directory missing"
  elif [[ ! -f "$QUALITY_DIR/package.json" ]]; then
    score=50
    message="package.json missing"
  else
    pushd "$QUALITY_DIR" >/dev/null
    if ! bun run typecheck >/dev/null 2>&1; then
      score=30
      message="type errors detected"
    fi

    # Count violations (using rg instead of grep)
    any_count=$(rg ': any\b|as any\b' src/ 2>/dev/null | wc -l | tr -d ' ') || any_count=0
    zinfer_count=$(rg 'z\.infer<|z\.input<|z\.output<' src/ 2>/dev/null | wc -l | tr -d ' ') || zinfer_count=0

    if [[ $any_count -gt 0 || $zinfer_count -gt 0 ]]; then
      score=$((score - any_count * 5 - zinfer_count * 10))
      [[ $score -lt 0 ]] && score=0
      message="violations: any=$any_count, z.infer=$zinfer_count"
    fi
    popd >/dev/null
  fi

  add_result "typescript" "$score" 20 "{\"score\":$score,\"message\":\"$message\",\"any_violations\":$any_count,\"zinfer_violations\":$zinfer_count}"
}

# Check 3: Hook Health (15%)
check_hooks() {
  local score=100
  local missing=0
  local total=0
  local valid_json=0

  # Actual hooks in the repository
  local hooks=(
    "paragon-guard.ts"
    "unified-polish.ts"
    "verification-gate.ts"
    "session-polish.ts"
    "session-start.sh"
    "session-stop.sh"
  )

  for hook in "${hooks[@]}"; do
    total=$((total + 1))
    if [[ ! -f "$AGENTS_DIR/hooks/$hook" ]]; then
      missing=$((missing + 1))
    elif [[ "$hook" == *.ts ]]; then
      # Check if TypeScript hooks have valid structure (using rg instead of grep)
      if rg -q "export default" "$AGENTS_DIR/hooks/$hook" 2>/dev/null || \
         rg -q "process.stdin" "$AGENTS_DIR/hooks/$hook" 2>/dev/null; then
        valid_json=$((valid_json + 1))
      fi
    fi
  done

  if [[ $total -gt 0 ]]; then
    score=$(( (total - missing) * 100 / total ))
  fi

  add_result "hooks" "$score" 15 "{\"score\":$score,\"missing\":$missing,\"total\":$total,\"valid_json\":$valid_json}"
}

# Check 4: Skills Integrity (10%)
check_skills() {
  local score=100
  local missing_md=0
  local total_skills=0
  local valid_refs=0

  if [[ -d "$AGENTS_DIR/skills" ]]; then
    for skill in "$AGENTS_DIR/skills"/*/; do
      if [[ -d "$skill" ]]; then
        total_skills=$((total_skills + 1))
        if [[ ! -f "$skill/SKILL.md" ]]; then
          missing_md=$((missing_md + 1))
        else
          # Check for valid cross-references (using rg instead of grep)
          if rg -q "## " "$skill/SKILL.md" 2>/dev/null; then
            valid_refs=$((valid_refs + 1))
          fi
        fi
      fi
    done
  fi

  if [[ $total_skills -gt 0 && $missing_md -gt 0 ]]; then
    score=$((100 - missing_md * 10))
    [[ $score -lt 0 ]] && score=0
  fi

  add_result "skills" "$score" 10 "{\"score\":$score,\"missing_md\":$missing_md,\"total\":$total_skills,\"valid_refs\":$valid_refs}"
}

# Check 5: Version Alignment (15%)
check_versions() {
  local score=100
  local message="ok"
  local drift_count=0

  local versions_ts="$QUALITY_DIR/src/stack/versions.ts"
  local versions_json="$QUALITY_DIR/versions.json"

  if [[ ! -f "$versions_ts" ]]; then
    score=0
    message="versions.ts missing (SSOT)"
  elif [[ -f "$versions_json" ]]; then
    # Extract ssotVersion from both files (using rg instead of grep)
    local ts_version json_version
    ts_version=$(rg -o "ssotVersion['\"]?\s*[:=]\s*['\"]?([0-9]+\.[0-9]+\.[0-9]+)" -r '$1' "$versions_ts" 2>/dev/null | head -1 || echo "")
    json_version=$(jq -r '.meta.ssotVersion // empty' "$versions_json" 2>/dev/null || echo "")

    if [[ -n "$ts_version" && -n "$json_version" && "$ts_version" != "$json_version" ]]; then
      score=70
      message="SSOT version mismatch: ts=$ts_version, json=$json_version"
      drift_count=$((drift_count + 1))
    fi
  fi

  add_result "versions" "$score" 15 "{\"score\":$score,\"message\":\"$message\",\"drift_count\":$drift_count}"
}

# Check 6: PARAGON Compliance (10%)
check_paragon() {
  local score=100
  local guard_count=14
  local active_guards=0
  local message="ok"

  local paragon_guard="$AGENTS_DIR/hooks/paragon-guard.ts"

  if [[ ! -f "$paragon_guard" ]]; then
    score=0
    message="paragon-guard.ts missing"
  else
    # Count active guard implementations (using rg instead of grep)
    active_guards=$(rg -c "function check[A-Z]|const check[A-Z]" "$paragon_guard" 2>/dev/null || echo 0)

    if [[ $active_guards -lt 10 ]]; then
      score=70
      message="only $active_guards guards active"
    fi
  fi

  add_result "paragon" "$score" 10 "{\"score\":$score,\"message\":\"$message\",\"guard_count\":$guard_count,\"active_guards\":$active_guards}"
}

# Check 7: Lessons Recency (10%)
check_lessons() {
  local score=100
  local lesson_count=0
  local days_since_last=999
  local category_balance="unknown"

  local lessons_file="$AGENTS_DIR/memory/lessons.md"

  if [[ ! -f "$lessons_file" ]]; then
    score=50
    lesson_count=0
  else
    # Count lesson entries (## headers or numbered items) - using rg instead of grep
    lesson_count=$(rg -c "^##|^\d+\." "$lessons_file" 2>/dev/null || echo 0)

    # Check file modification time
    # Use GNU stat -c if available (Nix), otherwise macOS stat -f
    local last_mod now
    if stat --version &>/dev/null; then
      # GNU coreutils stat
      last_mod=$(stat -c '%Y' "$lessons_file" 2>/dev/null || echo 0)
    else
      # BSD/macOS stat
      last_mod=$(/usr/bin/stat -f '%m' "$lessons_file" 2>/dev/null || echo 0)
    fi
    now=$(date +%s)
    days_since_last=$(( (now - last_mod) / 86400 ))

    # Score based on recency
    if [[ $days_since_last -gt 14 ]]; then
      score=$((score - 30))
    elif [[ $days_since_last -gt 7 ]]; then
      score=$((score - 15))
    fi

    # Score based on lesson count
    if [[ $lesson_count -lt 5 ]]; then
      score=$((score - 20))
    fi

    [[ $score -lt 0 ]] && score=0
  fi

  add_result "lessons" "$score" 10 "{\"score\":$score,\"lesson_count\":$lesson_count,\"days_since_last\":$days_since_last}"
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

# Show status dashboard
show_status() {
  echo "Evolution System Status"
  echo "======================="
  echo ""

  if [[ ! -f "$DB_FILE" ]]; then
    echo "No metrics database yet. Run 'just evolve' first."
    return
  fi

  echo "Recent Grades (last 5):"
  sqlite3 -header -column "$DB_FILE" "SELECT datetime(timestamp) as time, printf('%.0f%%', overall_score * 100) as score, recommendation FROM grades ORDER BY id DESC LIMIT 5;"

  echo ""
  echo "Weekly Trends:"
  sqlite3 -header -column "$DB_FILE" "SELECT date, printf('%.0f%%', avg_score * 100) as avg, printf('%.0f%%', min_score * 100) as min, printf('%.0f%%', max_score * 100) as max, check_count as checks FROM trends ORDER BY date DESC LIMIT 7;"

  echo ""
  echo "Lessons by Category:"
  sqlite3 -header -column "$DB_FILE" "SELECT category, COUNT(*) as count FROM lessons GROUP BY category ORDER BY count DESC;" 2>/dev/null || echo "  No lessons recorded yet."
}

# Main execution
main() {
  local cmd="${1:-grade}"

  case "$cmd" in
    status)
      show_status
      return
      ;;
    init)
      init_db
      echo "Database initialized at $DB_FILE"
      return
      ;;
    grade|*)
      ;;
  esac

  # Initialize database
  init_db

  # Run all checks
  check_nix_flake
  check_typescript
  check_hooks
  check_skills
  check_versions
  check_paragon
  check_lessons

  # Calculate results
  local overall_score recommendation timestamp
  overall_score=$(calculate_overall)
  recommendation=$(get_recommendation "$overall_score")
  timestamp=$(date -Iseconds)

  # Build final JSON
  local result
  result=$(jq -n \
    --arg score "$overall_score" \
    --arg rec "$recommendation" \
    --arg ts "$timestamp" \
    --argjson details "$DETAILS_JSON" \
    '{
      overall_score: ($score | tonumber),
      recommendation: $rec,
      timestamp: $ts,
      details: $details
    }')

  # Store in database
  store_grade "$overall_score" "$recommendation" "$timestamp" "$result"

  # Output final JSON
  echo "$result"
}

main "$@"
