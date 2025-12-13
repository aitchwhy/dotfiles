#!/usr/bin/env bash
# evolve.sh - Full evolution cycle (grade + reflect + recommend)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
METRICS_DIR="${HOME}/.claude-metrics"
DB_FILE="${METRICS_DIR}/evolution.db"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Show usage
usage() {
  echo "Usage: evolve.sh [command]"
  echo ""
  echo "Commands:"
  echo "  grade     Run grade check and store results (default)"
  echo "  status    Show evolution status dashboard"
  echo "  reflect   Analyze trends and suggest improvements"
  echo "  lesson    Add a lesson learned"
  echo "  history   Show grade history"
  echo "  reset     Reset metrics database"
  echo ""
}

# Run grade check
do_grade() {
  echo -e "${BLUE}Running Evolution Grade...${NC}"
  echo ""

  local result
  result=$("$SCRIPT_DIR/grade.sh")

  local score rec
  score=$(echo "$result" | jq -r '.overall_score')
  rec=$(echo "$result" | jq -r '.recommendation')

  # Color based on recommendation
  case "$rec" in
    ok)
      echo -e "${GREEN}✓ Overall Score: $(echo "$score * 100" | bc | cut -d. -f1)%${NC}"
      ;;
    warning)
      echo -e "${YELLOW}⚠ Overall Score: $(echo "$score * 100" | bc | cut -d. -f1)%${NC}"
      ;;
    urgent)
      echo -e "${RED}✗ Overall Score: $(echo "$score * 100" | bc | cut -d. -f1)%${NC}"
      ;;
  esac

  echo ""
  echo "Details:"
  echo "$result" | jq -r '.details | to_entries[] | "  \(.key): \(.value.score)% - \(.value.message // "ok")"'

  echo ""
  echo -e "${BLUE}Recommendation: $rec${NC}"
}

# Show status dashboard
do_status() {
  "$SCRIPT_DIR/grade.sh" status
}

# Analyze trends and suggest improvements
do_reflect() {
  echo -e "${BLUE}Evolution Reflection${NC}"
  echo "===================="
  echo ""

  if [[ ! -f "$DB_FILE" ]]; then
    echo "No metrics database yet. Run 'evolve grade' first."
    exit 1
  fi

  # Get recent trend
  local recent_avg last_week_avg trend
  recent_avg=$(sqlite3 "$DB_FILE" "SELECT AVG(overall_score) FROM grades WHERE timestamp > datetime('now', '-1 day');" 2>/dev/null || echo "0")
  last_week_avg=$(sqlite3 "$DB_FILE" "SELECT AVG(overall_score) FROM grades WHERE timestamp > datetime('now', '-7 days');" 2>/dev/null || echo "0")

  if [[ -n "$recent_avg" && -n "$last_week_avg" ]]; then
    trend=$(echo "scale=2; ($recent_avg - $last_week_avg) * 100" | bc 2>/dev/null || echo "0")

    if (( $(echo "$trend > 5" | bc -l) )); then
      echo -e "${GREEN}📈 Trending UP (+${trend}% vs last week)${NC}"
    elif (( $(echo "$trend < -5" | bc -l) )); then
      echo -e "${RED}📉 Trending DOWN (${trend}% vs last week)${NC}"
    else
      echo -e "${BLUE}📊 Stable (${trend}% change)${NC}"
    fi
  fi

  echo ""
  echo "Weak Areas (score < 80):"
  local last_grade
  last_grade=$(sqlite3 "$DB_FILE" "SELECT details_json FROM grades ORDER BY id DESC LIMIT 1;" 2>/dev/null)

  if [[ -n "$last_grade" ]]; then
    echo "$last_grade" | jq -r 'to_entries[] | select(.value.score < 80) | "  ⚠ \(.key): \(.value.score)%"'
  fi

  echo ""
  echo "Suggested Actions:"

  # Check for specific issues
  local nix_score ts_score hooks_score
  nix_score=$(echo "$last_grade" | jq -r '.nix_flake.score // 100')
  ts_score=$(echo "$last_grade" | jq -r '.typescript.score // 100')
  hooks_score=$(echo "$last_grade" | jq -r '.hooks.score // 100')

  if (( nix_score < 80 )); then
    echo "  1. Run 'nix flake check' to fix flake issues"
  fi

  if (( ts_score < 80 )); then
    echo "  2. Fix TypeScript errors: 'cd config/signet && bun run typecheck'"
  fi

  if (( hooks_score < 80 )); then
    echo "  3. Review missing hooks in config/agents/hooks/"
  fi

  echo ""
}

# Add a lesson learned
do_lesson() {
  echo "Add Lesson Learned"
  echo "=================="
  echo ""

  read -rp "Category (bug/pattern/optimization/gotcha): " category
  read -rp "Lesson: " lesson
  read -rp "Evidence: " evidence

  local date
  date=$(date +%Y-%m-%d)

  if [[ ! -f "$DB_FILE" ]]; then
    "$SCRIPT_DIR/grade.sh" init >/dev/null
  fi

  sqlite3 "$DB_FILE" "INSERT INTO lessons (date, category, lesson, evidence, source) VALUES ('$date', '$category', '$lesson', '$evidence', 'manual');"

  echo ""
  echo -e "${GREEN}✓ Lesson recorded${NC}"
}

# Show grade history
do_history() {
  echo "Grade History"
  echo "============="
  echo ""

  if [[ ! -f "$DB_FILE" ]]; then
    echo "No metrics database yet. Run 'evolve grade' first."
    exit 1
  fi

  sqlite3 -header -column "$DB_FILE" "
    SELECT
      datetime(timestamp) as time,
      printf('%.0f%%', overall_score * 100) as score,
      recommendation as rec
    FROM grades
    ORDER BY id DESC
    LIMIT 20;
  "
}

# Reset metrics database
do_reset() {
  echo -e "${YELLOW}Warning: This will delete all evolution metrics.${NC}"
  read -rp "Are you sure? (yes/no): " confirm

  if [[ "$confirm" == "yes" ]]; then
    rm -f "$DB_FILE"
    echo -e "${GREEN}✓ Metrics database reset${NC}"
  else
    echo "Cancelled."
  fi
}

# Main
main() {
  local cmd="${1:-grade}"

  case "$cmd" in
    grade)
      do_grade
      ;;
    status)
      do_status
      ;;
    reflect)
      do_reflect
      ;;
    lesson)
      do_lesson
      ;;
    history)
      do_history
      ;;
    reset)
      do_reset
      ;;
    -h|--help|help)
      usage
      ;;
    *)
      echo "Unknown command: $cmd"
      usage
      exit 1
      ;;
  esac
}

main "$@"
