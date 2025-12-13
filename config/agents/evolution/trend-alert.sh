#!/usr/bin/env bash
# trend-alert.sh - Trend analysis and alerting for evolution metrics
# Analyzes score patterns, detects degradation, generates alerts
set -euo pipefail

METRICS_DIR="${HOME}/.claude-metrics"
DB_FILE="${METRICS_DIR}/evolution.db"
ALERTS_FILE="${METRICS_DIR}/alerts.log"

# Alert thresholds
WARN_SCORE_THRESHOLD=0.80
URGENT_SCORE_THRESHOLD=0.50
SCORE_DROP_WARN=0.10       # 10% drop triggers warning
SCORE_DROP_URGENT=0.20     # 20% drop triggers urgent
CONSECUTIVE_FAILURES=2     # Consecutive low scores to trigger
STALE_LESSONS_DAYS=7       # Days without lessons update

# Colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize alerts file
init_alerts() {
  mkdir -p "$METRICS_DIR"
  touch "$ALERTS_FILE"
}

# Log an alert
log_alert() {
  local severity="$1"
  local message="$2"
  local timestamp
  timestamp=$(date -Iseconds)

  echo "$timestamp|$severity|$message" >> "$ALERTS_FILE"

  case "$severity" in
    urgent)
      echo -e "${RED}[URGENT]${NC} $message"
      ;;
    warning)
      echo -e "${YELLOW}[WARNING]${NC} $message"
      ;;
    info)
      echo -e "${BLUE}[INFO]${NC} $message"
      ;;
    *)
      echo "$message"
      ;;
  esac
}

# Check if database exists
require_db() {
  if [[ ! -f "$DB_FILE" ]]; then
    echo "No metrics database. Run 'just evolve' first."
    exit 1
  fi
}

# Analyze score trends
analyze_trends() {
  require_db

  echo "=== Trend Analysis ==="
  echo ""

  # Get current score
  local current_score
  current_score=$(sqlite3 "$DB_FILE" "SELECT overall_score FROM grades ORDER BY id DESC LIMIT 1;" 2>/dev/null || echo "0")

  # Get previous score
  local prev_score
  prev_score=$(sqlite3 "$DB_FILE" "SELECT overall_score FROM grades ORDER BY id DESC LIMIT 1 OFFSET 1;" 2>/dev/null || echo "$current_score")

  # Get average from last 7 days
  local avg_7d
  avg_7d=$(sqlite3 "$DB_FILE" "SELECT AVG(avg_score) FROM trends WHERE date >= date('now', '-7 days');" 2>/dev/null || echo "0")

  # Get average from last 30 days
  local avg_30d
  avg_30d=$(sqlite3 "$DB_FILE" "SELECT AVG(avg_score) FROM trends WHERE date >= date('now', '-30 days');" 2>/dev/null || echo "0")

  echo "Current Score:  $(printf '%.0f%%' "$(echo "$current_score * 100" | bc)")"
  echo "Previous Score: $(printf '%.0f%%' "$(echo "$prev_score * 100" | bc)")"
  echo "7-day Average:  $(printf '%.0f%%' "$(echo "$avg_7d * 100" | bc)")"
  echo "30-day Average: $(printf '%.0f%%' "$(echo "$avg_30d * 100" | bc)")"
  echo ""

  # Check for score drop
  local drop
  drop=$(echo "$prev_score - $current_score" | bc)

  if (( $(echo "$drop >= $SCORE_DROP_URGENT" | bc -l) )); then
    log_alert "urgent" "Score dropped $(printf '%.0f%%' "$(echo "$drop * 100" | bc)") (from $(printf '%.0f%%' "$(echo "$prev_score * 100" | bc)") to $(printf '%.0f%%' "$(echo "$current_score * 100" | bc)"))"
  elif (( $(echo "$drop >= $SCORE_DROP_WARN" | bc -l) )); then
    log_alert "warning" "Score dropped $(printf '%.0f%%' "$(echo "$drop * 100" | bc)") (from $(printf '%.0f%%' "$(echo "$prev_score * 100" | bc)") to $(printf '%.0f%%' "$(echo "$current_score * 100" | bc)"))"
  elif (( $(echo "$drop < 0" | bc -l) )); then
    # Score improved
    local improvement
    improvement=$(echo "$current_score - $prev_score" | bc)
    log_alert "info" "Score improved $(printf '%.0f%%' "$(echo "$improvement * 100" | bc)") (to $(printf '%.0f%%' "$(echo "$current_score * 100" | bc)"))"
  fi

  # Check absolute thresholds
  if (( $(echo "$current_score < $URGENT_SCORE_THRESHOLD" | bc -l) )); then
    log_alert "urgent" "Score below urgent threshold ($(printf '%.0f%%' "$(echo "$current_score * 100" | bc)") < $(printf '%.0f%%' "$(echo "$URGENT_SCORE_THRESHOLD * 100" | bc)"))"
  elif (( $(echo "$current_score < $WARN_SCORE_THRESHOLD" | bc -l) )); then
    log_alert "warning" "Score below warning threshold ($(printf '%.0f%%' "$(echo "$current_score * 100" | bc)") < $(printf '%.0f%%' "$(echo "$WARN_SCORE_THRESHOLD * 100" | bc)"))"
  fi

  # Check for consecutive low scores
  local low_count
  low_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM (SELECT overall_score FROM grades ORDER BY id DESC LIMIT $CONSECUTIVE_FAILURES) WHERE overall_score < $WARN_SCORE_THRESHOLD;" 2>/dev/null || echo "0")

  if [[ $low_count -ge $CONSECUTIVE_FAILURES ]]; then
    log_alert "urgent" "$low_count consecutive scores below $(printf '%.0f%%' "$(echo "$WARN_SCORE_THRESHOLD * 100" | bc)")"
  fi

  # Check lessons staleness
  local days_since_lesson
  days_since_lesson=$(sqlite3 "$DB_FILE" "SELECT CAST(julianday('now') - julianday(MAX(date)) AS INTEGER) FROM lessons;" 2>/dev/null || echo "999")

  if [[ "${days_since_lesson:-999}" -gt $STALE_LESSONS_DAYS ]]; then
    log_alert "warning" "No lessons recorded in ${days_since_lesson:-unknown} days"
  fi
}

# Generate trend report
generate_report() {
  require_db

  echo "=== Evolution Trend Report ==="
  echo "Generated: $(date)"
  echo ""

  # Weekly summary
  echo "## Weekly Summary"
  sqlite3 -header -column "$DB_FILE" "
    SELECT
      strftime('%W', date) as week,
      COUNT(*) as checks,
      printf('%.0f%%', AVG(avg_score) * 100) as avg_score,
      printf('%.0f%%', MIN(min_score) * 100) as worst,
      printf('%.0f%%', MAX(max_score) * 100) as best
    FROM trends
    WHERE date >= date('now', '-4 weeks')
    GROUP BY strftime('%W', date)
    ORDER BY week DESC;
  " 2>/dev/null || echo "No data available"
  echo ""

  # Component breakdown
  echo "## Component Health (Last 5 Checks)"
  sqlite3 "$DB_FILE" "
    SELECT json_extract(details_json, '$.nix_flake.score') as nix,
           json_extract(details_json, '$.typescript.score') as ts,
           json_extract(details_json, '$.hooks.score') as hooks,
           json_extract(details_json, '$.skills.score') as skills,
           json_extract(details_json, '$.paragon.score') as paragon
    FROM grades
    ORDER BY id DESC
    LIMIT 5;
  " 2>/dev/null | while IFS='|' read -r nix ts hooks skills paragon; do
    echo "  Nix: ${nix:-?}% | TS: ${ts:-?}% | Hooks: ${hooks:-?}% | Skills: ${skills:-?}% | PARAGON: ${paragon:-?}%"
  done
  echo ""

  # Velocity
  echo "## Velocity"
  local this_week last_week
  this_week=$(sqlite3 "$DB_FILE" "SELECT SUM(check_count) FROM trends WHERE date >= date('now', '-7 days');" 2>/dev/null || echo "0")
  last_week=$(sqlite3 "$DB_FILE" "SELECT SUM(check_count) FROM trends WHERE date >= date('now', '-14 days') AND date < date('now', '-7 days');" 2>/dev/null || echo "0")

  echo "  This week: ${this_week:-0} checks"
  echo "  Last week: ${last_week:-0} checks"

  if [[ "${last_week:-0}" -gt 0 ]]; then
    local change
    change=$(echo "scale=0; (($this_week - $last_week) * 100) / $last_week" | bc)
    echo "  Change: ${change}%"
  fi
  echo ""

  # Lessons summary
  echo "## Lessons Summary"
  sqlite3 -header -column "$DB_FILE" "
    SELECT category, COUNT(*) as count
    FROM lessons
    GROUP BY category
    ORDER BY count DESC;
  " 2>/dev/null || echo "  No lessons recorded"
  echo ""

  # Recent alerts
  echo "## Recent Alerts"
  if [[ -f "$ALERTS_FILE" ]]; then
    tail -10 "$ALERTS_FILE" | while IFS='|' read -r ts severity msg; do
      echo "  [$severity] $ts: $msg"
    done
  else
    echo "  No alerts"
  fi
}

# Check for degradation patterns
detect_degradation() {
  require_db

  echo "=== Degradation Detection ==="
  echo ""

  local issues=0

  # Check for declining trend (3+ consecutive drops)
  local declining
  declining=$(sqlite3 "$DB_FILE" "
    WITH scores AS (
      SELECT overall_score, LAG(overall_score) OVER (ORDER BY id) as prev
      FROM grades
      ORDER BY id DESC
      LIMIT 4
    )
    SELECT COUNT(*) FROM scores WHERE overall_score < prev;
  " 2>/dev/null || echo "0")

  if [[ $declining -ge 3 ]]; then
    log_alert "urgent" "Declining trend detected: 3+ consecutive score drops"
    issues=$((issues + 1))
  fi

  # Check for specific component degradation
  local components=("nix_flake" "typescript" "hooks" "skills" "paragon")

  for comp in "${components[@]}"; do
    local latest_score prev_score
    latest_score=$(sqlite3 "$DB_FILE" "
      SELECT json_extract(details_json, '$.$comp.score')
      FROM grades ORDER BY id DESC LIMIT 1;
    " 2>/dev/null || echo "100")

    prev_score=$(sqlite3 "$DB_FILE" "
      SELECT json_extract(details_json, '$.$comp.score')
      FROM grades ORDER BY id DESC LIMIT 1 OFFSET 1;
    " 2>/dev/null || echo "$latest_score")

    if [[ -n "$latest_score" && -n "$prev_score" ]]; then
      local drop
      drop=$(echo "$prev_score - $latest_score" | bc 2>/dev/null || echo "0")

      if [[ $(echo "$drop > 30" | bc 2>/dev/null || echo "0") -eq 1 ]]; then
        log_alert "warning" "Component '$comp' degraded: ${prev_score}% -> ${latest_score}%"
        issues=$((issues + 1))
      fi
    fi
  done

  if [[ $issues -eq 0 ]]; then
    echo -e "${GREEN}No degradation patterns detected.${NC}"
  fi

  echo ""
  echo "Issues detected: $issues"
}

# Show help
show_help() {
  cat <<EOF
Usage: $0 <command>

Commands:
  analyze     Analyze current trends and generate alerts
  report      Generate full trend report
  degradation Check for degradation patterns
  alerts      Show recent alerts
  clear       Clear alert history
  help        Show this help

Environment:
  METRICS_DIR    Metrics directory (default: ~/.claude-metrics)

Thresholds:
  Warning score:   ${WARN_SCORE_THRESHOLD} ($(printf '%.0f%%' "$(echo "$WARN_SCORE_THRESHOLD * 100" | bc)"))
  Urgent score:    ${URGENT_SCORE_THRESHOLD} ($(printf '%.0f%%' "$(echo "$URGENT_SCORE_THRESHOLD * 100" | bc)"))
  Score drop warn: ${SCORE_DROP_WARN} ($(printf '%.0f%%' "$(echo "$SCORE_DROP_WARN * 100" | bc)"))
  Score drop urgent: ${SCORE_DROP_URGENT} ($(printf '%.0f%%' "$(echo "$SCORE_DROP_URGENT * 100" | bc)"))
EOF
}

# Main
main() {
  local cmd="${1:-analyze}"

  init_alerts

  case "$cmd" in
    analyze)
      analyze_trends
      ;;
    report)
      generate_report
      ;;
    degradation)
      detect_degradation
      ;;
    alerts)
      if [[ -f "$ALERTS_FILE" ]]; then
        echo "=== Recent Alerts ==="
        tail -20 "$ALERTS_FILE" | while IFS='|' read -r ts severity msg; do
          case "$severity" in
            urgent) echo -e "${RED}[$severity]${NC} $ts: $msg" ;;
            warning) echo -e "${YELLOW}[$severity]${NC} $ts: $msg" ;;
            *) echo -e "${BLUE}[$severity]${NC} $ts: $msg" ;;
          esac
        done
      else
        echo "No alerts recorded."
      fi
      ;;
    clear)
      if [[ -f "$ALERTS_FILE" ]]; then
        rm "$ALERTS_FILE"
        echo "Alerts cleared."
      fi
      ;;
    help|--help|-h)
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
