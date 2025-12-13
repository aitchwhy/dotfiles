#!/usr/bin/env bash
# evolve.sh - Unified evolution system
# Single command for health checks, trends, alerts, and reports
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
METRICS_DIR="${HOME}/.claude-metrics"
DB_FILE="${METRICS_DIR}/evolution.db"
REPORTS_DIR="${METRICS_DIR}/reports"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
DIM='\033[2m'
NC='\033[0m'

# Auto-initialize on first run
auto_init() {
  mkdir -p "$METRICS_DIR" "$REPORTS_DIR"
  chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# UNIFIED DASHBOARD (default command)
# ═══════════════════════════════════════════════════════════════════════════════

do_dashboard() {
  auto_init

  echo ""
  echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║${NC}             ${GREEN}EVOLUTION SYSTEM DASHBOARD${NC}                       ${BLUE}║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""

  # Run grade and capture result
  local grade_result
  grade_result=$("$SCRIPT_DIR/grade.sh" 2>/dev/null) || grade_result='{"overall_score":0,"recommendation":"error"}'

  local score rec
  score=$(echo "$grade_result" | jq -r '.overall_score // 0')
  rec=$(echo "$grade_result" | jq -r '.recommendation // "error"')
  local score_pct
  score_pct=$(printf "%.0f" "$(echo "$score * 100" | bc)")

  # Score with color
  echo -n "  Health Score: "
  case "$rec" in
    ok)     echo -e "${GREEN}█████████████████████ ${score_pct}%${NC}" ;;
    warning) echo -e "${YELLOW}████████████████░░░░░ ${score_pct}%${NC}" ;;
    urgent) echo -e "${RED}████████░░░░░░░░░░░░░ ${score_pct}%${NC}" ;;
    *)      echo -e "${RED}░░░░░░░░░░░░░░░░░░░░░ ${score_pct}%${NC}" ;;
  esac
  echo ""

  # Component breakdown (compact)
  echo -e "  ${DIM}Components:${NC}"
  echo "$grade_result" | jq -r '.details | to_entries[] | "    \(.key): \(.value.score)%"' 2>/dev/null | head -7

  # Trend (if we have history)
  if [[ -f "$DB_FILE" ]]; then
    echo ""
    local trend_data
    trend_data=$(sqlite3 "$DB_FILE" "
      SELECT
        (SELECT overall_score FROM grades ORDER BY id DESC LIMIT 1) as current,
        (SELECT overall_score FROM grades ORDER BY id DESC LIMIT 1 OFFSET 1) as previous,
        (SELECT AVG(overall_score) FROM grades WHERE timestamp > datetime('now', '-7 days')) as week_avg
    " 2>/dev/null)

    if [[ -n "$trend_data" ]]; then
      local current prev week_avg
      IFS='|' read -r current prev week_avg <<< "$trend_data"

      if [[ -n "$prev" && -n "$current" ]]; then
        local diff
        diff=$(echo "scale=0; ($current - $prev) * 100" | bc 2>/dev/null || echo "0")
        diff=${diff:-0}

        echo -n "  Trend: "
        if (( diff > 5 )); then
          echo -e "${GREEN}↑ Improving (+${diff}%)${NC}"
        elif (( diff < -5 )); then
          echo -e "${RED}↓ Declining (${diff}%)${NC}"
        else
          echo -e "${BLUE}→ Stable${NC}"
        fi
      fi

      if [[ -n "$week_avg" ]]; then
        local week_pct
        week_pct=$(printf "%.0f" "$(echo "$week_avg * 100" | bc)")
        echo -e "  ${DIM}7-day average: ${week_pct}%${NC}"
      fi
    fi

    # Recent alerts (last 3)
    if [[ -f "$METRICS_DIR/alerts.log" ]]; then
      local recent_alerts
      recent_alerts=$(tail -3 "$METRICS_DIR/alerts.log" 2>/dev/null | grep -v "^$" || true)

      if [[ -n "$recent_alerts" ]]; then
        echo ""
        echo -e "  ${YELLOW}Recent Alerts:${NC}"
        echo "$recent_alerts" | while IFS='|' read -r ts severity msg; do
          case "$severity" in
            urgent)  echo -e "    ${RED}⚠${NC} $msg" ;;
            warning) echo -e "    ${YELLOW}!${NC} $msg" ;;
            *)       echo -e "    ${DIM}·${NC} $msg" ;;
          esac
        done
      fi
    fi

    # Quick recommendations
    echo ""
    echo -e "  ${DIM}Actions:${NC}"
    local weak_areas
    weak_areas=$(echo "$grade_result" | jq -r '.details | to_entries[] | select(.value.score < 80) | .key' 2>/dev/null)

    if [[ -z "$weak_areas" ]]; then
      echo -e "    ${GREEN}✓ All systems healthy${NC}"
    else
      echo "$weak_areas" | head -3 | while read -r area; do
        case "$area" in
          nix_flake)  echo "    → Run: nix flake check" ;;
          typescript) echo "    → Run: cd config/signet && bun typecheck" ;;
          hooks)      echo "    → Check: config/agents/hooks/" ;;
          paragon)    echo "    → Run: just paragon" ;;
          lessons)    echo "    → Add lessons: just evolve lesson" ;;
          *)          echo "    → Review: $area" ;;
        esac
      done
    fi
  fi

  echo ""
  echo -e "${DIM}  Commands: just evolve report | just evolve lesson | just evolve history${NC}"
  echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# REPORT GENERATION
# ═══════════════════════════════════════════════════════════════════════════════

do_report() {
  auto_init

  if [[ ! -f "$DB_FILE" ]]; then
    echo "No metrics yet. Run 'just evolve' first."
    exit 1
  fi

  # Generate report
  "$SCRIPT_DIR/weekly-report.sh" generate

  # Display it
  echo ""
  "$SCRIPT_DIR/weekly-report.sh" view
}

# ═══════════════════════════════════════════════════════════════════════════════
# LESSON RECORDING
# ═══════════════════════════════════════════════════════════════════════════════

do_lesson() {
  auto_init

  echo -e "${BLUE}Record Lesson Learned${NC}"
  echo ""

  read -rp "Category (bug/pattern/optimization/gotcha): " category
  read -rp "Lesson: " lesson
  read -rp "Evidence: " evidence

  local date
  date=$(date +%Y-%m-%d)

  # Ensure DB exists
  if [[ ! -f "$DB_FILE" ]]; then
    "$SCRIPT_DIR/grade.sh" init >/dev/null 2>&1
  fi

  # Escape quotes for SQLite
  lesson="${lesson//\'/\'\'}"
  evidence="${evidence//\'/\'\'}"

  sqlite3 "$DB_FILE" "INSERT INTO lessons (date, category, lesson, evidence, source) VALUES ('$date', '$category', '$lesson', '$evidence', 'manual');"

  echo ""
  echo -e "${GREEN}✓ Lesson recorded${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# HISTORY VIEW
# ═══════════════════════════════════════════════════════════════════════════════

do_history() {
  auto_init

  if [[ ! -f "$DB_FILE" ]]; then
    echo "No metrics yet. Run 'just evolve' first."
    exit 1
  fi

  echo -e "${BLUE}Grade History${NC}"
  echo ""

  sqlite3 -header -column "$DB_FILE" "
    SELECT
      datetime(timestamp) as time,
      printf('%.0f%%', overall_score * 100) as score,
      recommendation as status
    FROM grades
    ORDER BY id DESC
    LIMIT 15;
  "
}

# ═══════════════════════════════════════════════════════════════════════════════
# JSON OUTPUT (for MCP/programmatic access)
# ═══════════════════════════════════════════════════════════════════════════════

do_json() {
  auto_init

  local grade_result
  grade_result=$("$SCRIPT_DIR/grade.sh" 2>/dev/null) || grade_result='{"overall_score":0,"recommendation":"error"}'

  local score rec
  score=$(echo "$grade_result" | jq -r '.overall_score // 0')
  rec=$(echo "$grade_result" | jq -r '.recommendation // "error"')

  # Get trend
  local trend_direction="stable"
  local alert_count=0

  if [[ -f "$DB_FILE" ]]; then
    local current prev
    current=$(sqlite3 "$DB_FILE" "SELECT overall_score FROM grades ORDER BY id DESC LIMIT 1;" 2>/dev/null || echo "0")
    prev=$(sqlite3 "$DB_FILE" "SELECT overall_score FROM grades ORDER BY id DESC LIMIT 1 OFFSET 1;" 2>/dev/null || echo "$current")

    if [[ -n "$current" && -n "$prev" ]]; then
      local diff
      diff=$(echo "scale=2; ($current - $prev) * 100" | bc 2>/dev/null || echo "0")
      if (( $(echo "$diff > 5" | bc -l 2>/dev/null || echo "0") )); then
        trend_direction="improving"
      elif (( $(echo "$diff < -5" | bc -l 2>/dev/null || echo "0") )); then
        trend_direction="declining"
      fi
    fi

    if [[ -f "$METRICS_DIR/alerts.log" ]]; then
      alert_count=$(wc -l < "$METRICS_DIR/alerts.log" 2>/dev/null | tr -d ' ')
    fi
  fi

  # Build action items
  local action_items
  action_items=$(echo "$grade_result" | jq -c '[.details | to_entries[] | select(.value.score < 80) | .key]' 2>/dev/null || echo "[]")

  # Output JSON
  jq -n \
    --argjson score "$score" \
    --arg recommendation "$rec" \
    --arg trend "$trend_direction" \
    --argjson alert_count "$alert_count" \
    --argjson action_items "$action_items" \
    --argjson details "$(echo "$grade_result" | jq '.details // {}')" \
    '{
      score: $score,
      score_percent: ($score * 100 | floor),
      recommendation: $recommendation,
      trend: $trend,
      alert_count: $alert_count,
      action_items: $action_items,
      details: $details
    }'
}

# ═══════════════════════════════════════════════════════════════════════════════
# HELP
# ═══════════════════════════════════════════════════════════════════════════════

show_help() {
  cat << EOF
Usage: evolve [command]

Commands:
  (none)    Show unified dashboard (grade + trends + alerts)
  report    Generate and display weekly report
  lesson    Record a lesson learned
  history   Show grade history
  json      Output JSON for programmatic access

Examples:
  just evolve              # Full dashboard
  just evolve report       # Weekly report
  just evolve lesson       # Add lesson
  just evolve json         # Machine-readable output

EOF
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
  local cmd="${1:-}"

  case "$cmd" in
    ""|dashboard)
      do_dashboard
      ;;
    report)
      do_report
      ;;
    lesson)
      do_lesson
      ;;
    history)
      do_history
      ;;
    json)
      do_json
      ;;
    # Hidden commands for backward compatibility
    grade)
      "$SCRIPT_DIR/grade.sh"
      ;;
    status)
      do_dashboard
      ;;
    reflect)
      do_dashboard
      ;;
    -h|--help|help)
      show_help
      ;;
    *)
      echo "Unknown command: $cmd"
      show_help
      exit 1
      ;;
  esac
}

main "$@"
