#!/usr/bin/env bash
# health-monitor.sh - Background health monitor for Evolution system
# Designed to run as a launchd user agent
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
METRICS_DIR="${METRICS_DIR:-$HOME/.claude-metrics}"
LOGFILE="$METRICS_DIR/health-monitor.log"
INTERVAL="${HEALTH_MONITOR_INTERVAL:-3600}" # Default: 1 hour

mkdir -p "$METRICS_DIR"

log() {
  echo "[$(date -Iseconds)] $1" >>"$LOGFILE"
}

run_health_check() {
  log "Starting health check..."

  local SCORE="?"
  local REC="unknown"
  local GRADER_SCRIPT="$DOTFILES/config/agents/evolution/grade.sh"

  # Run graders if available
  if [[ -x "$GRADER_SCRIPT" ]]; then
    if "$GRADER_SCRIPT" >"$METRICS_DIR/latest.json.tmp" 2>/dev/null; then
      mv "$METRICS_DIR/latest.json.tmp" "$METRICS_DIR/latest.json"

      # Extract score for logging (requires jq)
      if command -v jq &>/dev/null && [[ -f "$METRICS_DIR/latest.json" ]]; then
        SCORE=$(jq -r '.overall_score * 100 | floor // "?"' "$METRICS_DIR/latest.json" 2>/dev/null || echo "?")
        REC=$(jq -r '.recommendation // "unknown"' "$METRICS_DIR/latest.json" 2>/dev/null || echo "unknown")
      fi

      log "Health check complete: ${SCORE}% ($REC)"

      # Append to history
      if [[ -f "$METRICS_DIR/latest.json" ]]; then
        jq -c '.' "$METRICS_DIR/latest.json" >>"$METRICS_DIR/history.jsonl" 2>/dev/null || true
      fi

      # Send notification if urgent (macOS only)
      if [[ "$REC" == "urgent" ]] && command -v osascript &>/dev/null; then
        osascript -e "display notification \"Score: ${SCORE}% - Needs attention\" with title \"Dotfiles Health\"" 2>/dev/null || true
      fi
    else
      log "Health check failed (grader returned non-zero)"
      rm -f "$METRICS_DIR/latest.json.tmp"
    fi
  else
    # Fallback: run basic nix flake check
    log "Grader not found, running basic flake check..."
    if nix flake check "$DOTFILES" --no-build 2>/dev/null; then
      log "Flake check passed"
    else
      log "Flake check failed"
    fi
  fi
}

# Cleanup old logs (keep last 1000 lines)
cleanup_logs() {
  if [[ -f "$LOGFILE" ]] && [[ $(wc -l <"$LOGFILE") -gt 1000 ]]; then
    tail -1000 "$LOGFILE" >"$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
  fi
}

# Main execution
main() {
  log "Health monitor started (interval: ${INTERVAL}s)"

  # Run once immediately
  run_health_check
  cleanup_logs

  # If running as daemon (not one-shot), loop
  if [[ "${ONESHOT:-false}" != "true" ]]; then
    while true; do
      sleep "$INTERVAL"
      run_health_check
      cleanup_logs
    done
  fi
}

main "$@"
