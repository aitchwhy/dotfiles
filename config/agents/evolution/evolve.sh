#!/usr/bin/env bash
# evolve.sh - Unified evolution system
# Single command: just evolve [--json]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
METRICS_DIR="${HOME}/.claude-metrics"
DB_FILE="${METRICS_DIR}/evolution.db"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# Auto-initialize on first run
auto_init() {
  mkdir -p "$METRICS_DIR"
  chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true
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

  # Get weekly stats
  local week_sessions=0 week_lessons=0 week_avg=0
  if [[ -f "$DB_FILE" ]]; then
    week_sessions=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM grades WHERE timestamp > datetime('now', '-7 days');" 2>/dev/null || echo "0")
    week_lessons=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM lessons WHERE date > date('now', '-7 days');" 2>/dev/null || echo "0")
    week_avg=$(sqlite3 "$DB_FILE" "SELECT printf('%.0f', AVG(overall_score) * 100) FROM grades WHERE timestamp > datetime('now', '-7 days');" 2>/dev/null || echo "0")
  fi

  # Get active lessons
  local lessons_json="[]"
  if [[ -f "$DB_FILE" ]]; then
    lessons_json=$(sqlite3 -json "$DB_FILE" "
      SELECT category, lesson as text, occurrence_count as count, printf('%.2f', decay_score) as decay
      FROM lessons
      ORDER BY decay_score DESC
      LIMIT 10;
    " 2>/dev/null || echo "[]")
  fi

  # Get memory stats
  local active_count=0 archived_count=0 last_gc="never"
  if [[ -f "$DB_FILE" ]]; then
    active_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM lessons;" 2>/dev/null || echo "0")
    archived_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM lessons_archive;" 2>/dev/null || echo "0")
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
    --argjson week_sessions "$week_sessions" \
    --argjson week_lessons "$week_lessons" \
    --argjson week_avg "${week_avg:-0}" \
    --argjson lessons "$lessons_json" \
    --argjson active "$active_count" \
    --argjson archived "$archived_count" \
    '{
      score: $score,
      score_percent: ($score * 100 | floor),
      recommendation: $recommendation,
      trend: $trend,
      alert_count: $alert_count,
      action_items: $action_items,
      details: $details,
      week: {
        sessions: $week_sessions,
        lessons: $week_lessons,
        avg_score: $week_avg
      },
      lessons: $lessons,
      memory: {
        active: $active,
        archived: $archived
      }
    }'
}

# ═══════════════════════════════════════════════════════════════════════════════
# UNIFIED DASHBOARD (default command)
# ═══════════════════════════════════════════════════════════════════════════════

do_dashboard() {
  auto_init

  echo ""
  echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║${NC}                  ${BOLD}EVOLUTION SYSTEM${NC}                            ${BLUE}║${NC}"
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

  # Get trend
  local trend_text="→ Stable"
  local trend_color="$BLUE"
  if [[ -f "$DB_FILE" ]]; then
    local current prev
    current=$(sqlite3 "$DB_FILE" "SELECT overall_score FROM grades ORDER BY id DESC LIMIT 1;" 2>/dev/null || echo "0")
    prev=$(sqlite3 "$DB_FILE" "SELECT overall_score FROM grades ORDER BY id DESC LIMIT 1 OFFSET 1;" 2>/dev/null || echo "$current")

    if [[ -n "$prev" && -n "$current" ]]; then
      local diff
      diff=$(printf "%.0f" "$(echo "scale=0; ($current - $prev) * 100" | bc 2>/dev/null || echo "0")")
      if (( diff > 5 )); then
        trend_text="↑ Improving (+${diff}%)"
        trend_color="$GREEN"
      elif (( diff < -5 )); then
        trend_text="↓ Declining (${diff}%)"
        trend_color="$RED"
      fi
    fi
  fi

  # Health score with bar
  local bar=""
  local filled=$((score_pct / 5))
  local empty=$((20 - filled))
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done

  local score_color="$GREEN"
  case "$rec" in
    warning) score_color="$YELLOW" ;;
    urgent|error) score_color="$RED" ;;
  esac

  echo -e "  ${BOLD}HEALTH${NC}  ${score_color}${bar} ${score_pct}%${NC}  ${trend_color}${trend_text}${NC}"
  echo ""

  # Components box
  echo -e "  ${DIM}┌─ Components ──────────────────────────────────────────────┐${NC}"
  local components
  components=$(echo "$grade_result" | jq -r '.details | to_entries[] | "\(.key): \(.value.score)%"' 2>/dev/null | head -6 | tr '\n' '  ')
  echo -e "  ${DIM}│${NC}  ${components}${DIM}│${NC}"
  echo -e "  ${DIM}└────────────────────────────────────────────────────────────┘${NC}"
  echo ""

  # Weekly stats box
  if [[ -f "$DB_FILE" ]]; then
    local week_sessions week_lessons week_avg best_day
    week_sessions=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM grades WHERE timestamp > datetime('now', '-7 days');" 2>/dev/null || echo "0")
    week_lessons=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM lessons WHERE date > date('now', '-7 days');" 2>/dev/null || echo "0")
    week_avg=$(sqlite3 "$DB_FILE" "SELECT printf('%.0f', AVG(overall_score) * 100) FROM grades WHERE timestamp > datetime('now', '-7 days');" 2>/dev/null || echo "N/A")
    best_day=$(sqlite3 "$DB_FILE" "SELECT strftime('%a', timestamp) FROM grades WHERE timestamp > datetime('now', '-7 days') ORDER BY overall_score DESC LIMIT 1;" 2>/dev/null || echo "N/A")

    echo -e "  ${DIM}┌─ This Week ────────────────────────────────────────────────┐${NC}"
    echo -e "  ${DIM}│${NC}  Sessions: ${CYAN}${week_sessions}${NC}  |  Lessons: ${CYAN}${week_lessons}${NC}  |  Avg Score: ${CYAN}${week_avg}%${NC}      ${DIM}│${NC}"
    echo -e "  ${DIM}│${NC}  Best day: ${best_day}  |  Trend: ${trend_text}                      ${DIM}│${NC}"
    echo -e "  ${DIM}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
  fi

  # Active lessons box
  if [[ -f "$DB_FILE" ]]; then
    local lessons_count
    lessons_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM lessons;" 2>/dev/null || echo "0")

    if [[ "$lessons_count" -gt 0 ]]; then
      echo -e "  ${DIM}┌─ Active Lessons (by decay score) ─────────────────────────┐${NC}"

      sqlite3 "$DB_FILE" "
        SELECT category, lesson, occurrence_count, decay_score
        FROM lessons
        ORDER BY decay_score DESC
        LIMIT 4;
      " 2>/dev/null | while IFS='|' read -r cat lesson count decay; do
        # Truncate lesson to fit
        local short_lesson
        short_lesson=$(echo "$lesson" | cut -c1-40)
        [[ ${#lesson} -gt 40 ]] && short_lesson="${short_lesson}..."

        # Decay bar (3 chars)
        local decay_pct decay_bar=""
        decay_pct=$(printf "%.0f" "$(echo "$decay * 100" | bc)")
        if (( decay_pct >= 66 )); then decay_bar="▓▓▓"
        elif (( decay_pct >= 33 )); then decay_bar="▓▓░"
        else decay_bar="▓░░"
        fi

        printf "  ${DIM}│${NC}  [${CYAN}%-11s${NC}] %-40s (${count}x) ${decay_bar}${DIM}│${NC}\n" "$cat" "$short_lesson"
      done

      echo -e "  ${DIM}└────────────────────────────────────────────────────────────┘${NC}"
      echo ""
    fi
  fi

  # Memory stats box
  if [[ -f "$DB_FILE" ]]; then
    local active_count archived_count
    active_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM lessons;" 2>/dev/null || echo "0")
    archived_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM lessons_archive;" 2>/dev/null || echo "0")

    echo -e "  ${DIM}┌─ Memory Stats ─────────────────────────────────────────────┐${NC}"
    echo -e "  ${DIM}│${NC}  Active: ${GREEN}${active_count}${NC} lessons  |  Archived: ${DIM}${archived_count}${NC}                       ${DIM}│${NC}"
    echo -e "  ${DIM}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
  fi

  # Alerts
  if [[ -f "$METRICS_DIR/alerts.log" ]]; then
    local recent_alerts
    recent_alerts=$(tail -3 "$METRICS_DIR/alerts.log" 2>/dev/null | grep -v "^$" || true)

    if [[ -n "$recent_alerts" ]]; then
      echo -e "  ${YELLOW}Alerts:${NC}"
      echo "$recent_alerts" | while IFS='|' read -r ts severity msg; do
        case "$severity" in
          urgent)  echo -e "    ${RED}⚠${NC} $msg" ;;
          warning) echo -e "    ${YELLOW}!${NC} $msg" ;;
          *)       echo -e "    ${DIM}·${NC} $msg" ;;
        esac
      done
      echo ""
    else
      echo -e "  ${DIM}Alerts: None${NC}"
      echo ""
    fi
  else
    echo -e "  ${DIM}Alerts: None${NC}"
    echo ""
  fi

  # Actions
  local weak_areas
  weak_areas=$(echo "$grade_result" | jq -r '.details | to_entries[] | select(.value.score < 80) | .key' 2>/dev/null)

  if [[ -z "$weak_areas" ]]; then
    echo -e "  ${GREEN}✓ All systems healthy${NC}"
  else
    echo -e "  ${DIM}Actions:${NC}"
    echo "$weak_areas" | head -3 | while read -r area; do
      case "$area" in
        nix_flake)  echo "    → Run: nix flake check" ;;
        typescript) echo "    → Run: bun typecheck" ;;
        hooks)      echo "    → Check: config/agents/hooks/" ;;
        paragon)    echo "    → Run: just paragon" ;;
        lessons)    echo "    → Lessons will be captured automatically" ;;
        *)          echo "    → Review: $area" ;;
      esac
    done
  fi

  echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# HELP
# ═══════════════════════════════════════════════════════════════════════════════

show_help() {
  cat << EOF
Usage: just evolve [--json]

Unified evolution system dashboard.

Options:
  --json    Output machine-readable JSON (for MCP tools)
  -h        Show this help

Examples:
  just evolve          # Show unified dashboard
  just evolve --json   # JSON output for programmatic access

Automatic lesson learning runs via session hooks.
Memory consolidation happens automatically after each session.
EOF
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
  local arg="${1:-}"

  case "$arg" in
    --json|json)
      do_json
      ;;
    -h|--help|help)
      show_help
      ;;
    ""|dashboard)
      do_dashboard
      ;;
    # Hidden backward compatibility
    report|history|lesson|grade|status|reflect)
      do_dashboard
      ;;
    *)
      echo "Unknown option: $arg"
      show_help
      exit 1
      ;;
  esac
}

main "$@"
