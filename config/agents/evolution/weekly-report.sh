#!/usr/bin/env bash
# weekly-report.sh - Generate weekly evolution system reports
# Designed to run via cron or launchd for automated reporting
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
METRICS_DIR="${HOME}/.claude-metrics"
DB_FILE="${METRICS_DIR}/evolution.db"
REPORTS_DIR="${METRICS_DIR}/reports"
EVOLUTION_DIR="$DOTFILES/config/agents/evolution"

# Ensure directories exist
mkdir -p "$REPORTS_DIR"

# Generate markdown report
generate_markdown_report() {
  local report_file="$1"
  local week_start week_end
  week_start=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d)
  week_end=$(date +%Y-%m-%d)

  cat > "$report_file" << EOF
# Evolution System Weekly Report

**Period**: $week_start to $week_end
**Generated**: $(date)

---

## Executive Summary

EOF

  # Get overall stats
  local avg_score check_count alerts_count
  avg_score=$(sqlite3 "$DB_FILE" "
    SELECT printf('%.0f', AVG(avg_score) * 100)
    FROM trends
    WHERE date >= '$week_start';
  " 2>/dev/null || echo "N/A")

  check_count=$(sqlite3 "$DB_FILE" "
    SELECT SUM(check_count)
    FROM trends
    WHERE date >= '$week_start';
  " 2>/dev/null || echo "0")

  alerts_count=$(grep -c "^$(date +%Y)" "$METRICS_DIR/alerts.log" 2>/dev/null || echo "0")

  cat >> "$report_file" << EOF
| Metric | Value |
|--------|-------|
| Average Score | ${avg_score:-N/A}% |
| Total Checks | ${check_count:-0} |
| Alerts Generated | ${alerts_count:-0} |

EOF

  # Trend direction
  local trend_direction="stable"
  local first_score last_score
  first_score=$(sqlite3 "$DB_FILE" "
    SELECT avg_score FROM trends
    WHERE date >= '$week_start'
    ORDER BY date ASC LIMIT 1;
  " 2>/dev/null || echo "0")

  last_score=$(sqlite3 "$DB_FILE" "
    SELECT avg_score FROM trends
    WHERE date >= '$week_start'
    ORDER BY date DESC LIMIT 1;
  " 2>/dev/null || echo "0")

  if [[ -n "$first_score" && -n "$last_score" ]]; then
    local diff
    diff=$(echo "($last_score - $first_score) * 100" | bc 2>/dev/null || echo "0")
    if (( $(echo "$diff > 5" | bc -l 2>/dev/null || echo "0") )); then
      trend_direction="improving (+$(printf '%.0f' "$diff")%)"
    elif (( $(echo "$diff < -5" | bc -l 2>/dev/null || echo "0") )); then
      trend_direction="declining ($(printf '%.0f' "$diff")%)"
    fi
  fi

  cat >> "$report_file" << EOF
**Trend**: $trend_direction

---

## Daily Breakdown

| Date | Avg Score | Min | Max | Checks |
|------|-----------|-----|-----|--------|
EOF

  sqlite3 "$DB_FILE" "
    SELECT date,
           printf('%.0f%%', avg_score * 100),
           printf('%.0f%%', min_score * 100),
           printf('%.0f%%', max_score * 100),
           check_count
    FROM trends
    WHERE date >= '$week_start'
    ORDER BY date DESC;
  " 2>/dev/null | while IFS='|' read -r date avg min max checks; do
    echo "| $date | $avg | $min | $max | $checks |" >> "$report_file"
  done

  cat >> "$report_file" << EOF

---

## Component Health

EOF

  # Get latest component scores
  sqlite3 "$DB_FILE" "
    SELECT
      json_extract(details_json, '$.nix_flake.score') as nix,
      json_extract(details_json, '$.typescript.score') as ts,
      json_extract(details_json, '$.hooks.score') as hooks,
      json_extract(details_json, '$.skills.score') as skills,
      json_extract(details_json, '$.versions.score') as versions,
      json_extract(details_json, '$.paragon.score') as paragon,
      json_extract(details_json, '$.lessons.score') as lessons
    FROM grades
    ORDER BY id DESC
    LIMIT 1;
  " 2>/dev/null | while IFS='|' read -r nix ts hooks skills versions paragon lessons; do
    cat >> "$report_file" << EOF
| Component | Score | Status |
|-----------|-------|--------|
| Nix Flake | ${nix:-?}% | $(score_status "${nix:-0}") |
| TypeScript | ${ts:-?}% | $(score_status "${ts:-0}") |
| Hooks | ${hooks:-?}% | $(score_status "${hooks:-0}") |
| Skills | ${skills:-?}% | $(score_status "${skills:-0}") |
| Versions | ${versions:-?}% | $(score_status "${versions:-0}") |
| PARAGON | ${paragon:-?}% | $(score_status "${paragon:-0}") |
| Lessons | ${lessons:-?}% | $(score_status "${lessons:-0}") |

EOF
  done

  # Lessons section
  cat >> "$report_file" << EOF
---

## Lessons Learned This Week

EOF

  local lessons_this_week
  lessons_this_week=$(sqlite3 "$DB_FILE" "
    SELECT category, lesson, evidence
    FROM lessons
    WHERE date >= '$week_start'
    ORDER BY date DESC;
  " 2>/dev/null || echo "")

  if [[ -n "$lessons_this_week" ]]; then
    echo "$lessons_this_week" | while IFS='|' read -r category lesson evidence; do
      cat >> "$report_file" << EOF
### [$category] $lesson

> Evidence: $evidence

EOF
    done
  else
    echo "_No new lessons recorded this week._" >> "$report_file"
  fi

  # Alerts section
  cat >> "$report_file" << EOF
---

## Alerts This Week

EOF

  if [[ -f "$METRICS_DIR/alerts.log" ]]; then
    local alerts
    alerts=$(grep "^${week_start}\|^$(date +%Y)" "$METRICS_DIR/alerts.log" 2>/dev/null | tail -20 || echo "")
    if [[ -n "$alerts" ]]; then
      echo '```' >> "$report_file"
      echo "$alerts" >> "$report_file"
      echo '```' >> "$report_file"
    else
      echo "_No alerts this week._" >> "$report_file"
    fi
  else
    echo "_No alerts recorded._" >> "$report_file"
  fi

  # Recommendations
  cat >> "$report_file" << EOF

---

## Recommendations

EOF

  # Generate recommendations based on data
  if [[ "${avg_score:-100}" -lt 80 ]]; then
    echo "- **Priority**: Focus on improving overall score (currently ${avg_score}%)" >> "$report_file"
  fi

  local lesson_count
  lesson_count=$(sqlite3 "$DB_FILE" "
    SELECT COUNT(*) FROM lessons WHERE date >= '$week_start';
  " 2>/dev/null || echo "0")

  if [[ "${lesson_count:-0}" -lt 2 ]]; then
    echo "- **Documentation**: Record more lessons learned (only ${lesson_count:-0} this week)" >> "$report_file"
  fi

  if [[ "${check_count:-0}" -lt 5 ]]; then
    echo "- **Monitoring**: Increase evolution check frequency (only ${check_count:-0} checks this week)" >> "$report_file"
  fi

  # Add improvement suggestions if no other recommendations
  if [[ "${avg_score:-0}" -ge 80 && "${lesson_count:-0}" -ge 2 && "${check_count:-0}" -ge 5 ]]; then
    echo "_System is healthy. No immediate actions required._" >> "$report_file"
  fi

  cat >> "$report_file" << EOF

---

_Report generated by evolution/weekly-report.sh_
EOF
}

# Helper to convert score to status emoji
score_status() {
  local score="${1:-0}"
  if [[ $score -ge 90 ]]; then
    echo "Excellent"
  elif [[ $score -ge 80 ]]; then
    echo "Good"
  elif [[ $score -ge 50 ]]; then
    echo "Warning"
  else
    echo "Critical"
  fi
}

# Generate JSON report for programmatic access
generate_json_report() {
  local report_file="$1"
  local week_start
  week_start=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d)

  sqlite3 "$DB_FILE" "
    SELECT json_object(
      'period_start', '$week_start',
      'period_end', date('now'),
      'generated_at', datetime('now'),
      'summary', json_object(
        'avg_score', (SELECT AVG(avg_score) FROM trends WHERE date >= '$week_start'),
        'min_score', (SELECT MIN(min_score) FROM trends WHERE date >= '$week_start'),
        'max_score', (SELECT MAX(max_score) FROM trends WHERE date >= '$week_start'),
        'total_checks', (SELECT SUM(check_count) FROM trends WHERE date >= '$week_start'),
        'lesson_count', (SELECT COUNT(*) FROM lessons WHERE date >= '$week_start')
      ),
      'daily_data', (
        SELECT json_group_array(json_object(
          'date', date,
          'avg_score', avg_score,
          'min_score', min_score,
          'max_score', max_score,
          'check_count', check_count
        ))
        FROM trends
        WHERE date >= '$week_start'
        ORDER BY date DESC
      )
    );
  " 2>/dev/null > "$report_file"
}

# Send report notification (placeholder for Slack/email integration)
send_notification() {
  local report_file="$1"
  local avg_score="$2"

  # Placeholder: Could integrate with Slack, email, or macOS notifications

  # macOS notification
  if command -v osascript &>/dev/null; then
    local title="Evolution Weekly Report"
    local message="Average score: ${avg_score}%. Report saved to ${report_file}"
    osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null || true
  fi

  echo "Report saved: $report_file"
}

# Main
main() {
  local cmd="${1:-generate}"

  if [[ ! -f "$DB_FILE" ]]; then
    echo "Error: No metrics database. Run 'just evolve' to generate data."
    exit 1
  fi

  local week_num
  week_num=$(date +%Y-W%V)

  case "$cmd" in
    generate)
      local md_report="$REPORTS_DIR/weekly-$week_num.md"
      local json_report="$REPORTS_DIR/weekly-$week_num.json"

      echo "Generating weekly report for $week_num..."

      generate_markdown_report "$md_report"
      generate_json_report "$json_report"

      local avg_score
      avg_score=$(sqlite3 "$DB_FILE" "
        SELECT printf('%.0f', AVG(avg_score) * 100)
        FROM trends
        WHERE date >= date('now', '-7 days');
      " 2>/dev/null || echo "N/A")

      send_notification "$md_report" "$avg_score"

      echo ""
      echo "Reports generated:"
      echo "  Markdown: $md_report"
      echo "  JSON: $json_report"
      ;;

    view)
      local latest
      latest=$(ls -t "$REPORTS_DIR"/weekly-*.md 2>/dev/null | head -1 || echo "")
      if [[ -n "$latest" ]]; then
        cat "$latest"
      else
        echo "No reports found. Run '$0 generate' first."
      fi
      ;;

    list)
      echo "Available reports:"
      ls -la "$REPORTS_DIR"/weekly-*.md 2>/dev/null || echo "  No reports found."
      ;;

    clean)
      local keep="${2:-4}"
      echo "Keeping last $keep reports..."
      ls -t "$REPORTS_DIR"/weekly-*.md 2>/dev/null | tail -n +$((keep + 1)) | xargs rm -f
      ls -t "$REPORTS_DIR"/weekly-*.json 2>/dev/null | tail -n +$((keep + 1)) | xargs rm -f
      echo "Done."
      ;;

    help|--help|-h)
      cat << EOF
Usage: $0 <command>

Commands:
  generate    Generate weekly report (default)
  view        View latest report
  list        List all reports
  clean [n]   Keep only last n reports (default: 4)
  help        Show this help

Reports are saved to: $REPORTS_DIR
EOF
      ;;

    *)
      echo "Unknown command: $cmd"
      exit 1
      ;;
  esac
}

main "$@"
