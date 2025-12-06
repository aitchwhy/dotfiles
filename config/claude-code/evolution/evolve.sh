#!/usr/bin/env bash
# Self-Evolution Main Command
# Usage: evolve.sh [status|grade|reflect|lessons|history]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
METRICS="$DOTFILES/.claude-metrics"

case "${1:-}" in
    status)
        if [[ ! -f "$METRICS/latest.json" ]]; then
            echo "No metrics found. Run: just evolve"
            exit 0
        fi

        L=$(cat "$METRICS/latest.json")

        # Get age of metrics (use date -r on macOS, stat on Linux)
        if [[ "$(uname)" == "Darwin" ]]; then
            MTIME=$(date -r "$METRICS/latest.json" +%s 2>/dev/null || echo 0)
        else
            MTIME=$(stat -c %Y "$METRICS/latest.json" 2>/dev/null || echo 0)
        fi
        AGE=$(( ($(date +%s) - MTIME) / 3600 ))

        SCORE=$(echo "$L" | jq -r '.overall_score * 100 | floor')
        REC=$(echo "$L" | jq -r '.recommendation')

        echo "╔═══════════════════════════════════════╗"
        echo "║        EVOLUTION STATUS               ║"
        echo "╠═══════════════════════════════════════╣"
        printf "║  Score: %-28s ║\n" "${SCORE}%"
        printf "║  Status: %-27s ║\n" "$REC"
        printf "║  Age: %-30s ║\n" "${AGE}h ago"
        echo "╚═══════════════════════════════════════╝"
        echo ""
        echo "Breakdown:"
        echo "$L" | jq -r '.graders[] | "  \(.grader): \(.score * 100 | floor)% \(if .passed then "✓" else "✗" end)"'

        # Show issues if any
        ISSUES=$(echo "$L" | jq -r '.graders[].issues[]?' | head -5)
        if [[ -n "$ISSUES" ]]; then
            echo ""
            echo "Top issues:"
            echo "$ISSUES" | while read -r i; do
                [[ -n "$i" ]] && echo "  • $i"
            done
        fi
        ;;

    grade)
        "$SCRIPT_DIR/grade.sh"
        ;;

    reflect)
        "$SCRIPT_DIR/reflect.sh"
        ;;

    lessons)
        LFILE="$SCRIPT_DIR/lessons/lessons.jsonl"
        if [[ ! -f "$LFILE" || ! -s "$LFILE" ]]; then
            echo "No lessons recorded yet."
            exit 0
        fi

        echo "Recent Lessons:"
        echo "───────────────"
        tail -10 "$LFILE" | jq -r '"[\(.timestamp | .[0:10])] \(.lesson)"' 2>/dev/null || cat "$LFILE"
        ;;

    history)
        if [[ ! -f "$METRICS/history.jsonl" ]]; then
            echo "No history recorded yet."
            exit 0
        fi

        echo "Score History:"
        echo "──────────────"
        tail -10 "$METRICS/history.jsonl" | jq -r '"\(.timestamp | .[0:10]) │ \(.overall_score * 100 | floor)% │ \(.recommendation)"'
        ;;

    help|--help|-h)
        echo "Self-Evolution System"
        echo ""
        echo "Usage: evolve.sh [command]"
        echo ""
        echo "Commands:"
        echo "  (none)    Full cycle: grade + reflect"
        echo "  status    Show current score and breakdown"
        echo "  grade     Run graders only (no reflection)"
        echo "  reflect   Analyze issues and propose fixes"
        echo "  lessons   View accumulated lessons"
        echo "  history   View score history"
        echo "  help      Show this help"
        ;;

    *)
        # Default: full evolution cycle
        echo "Running full evolution cycle..."
        echo ""

        # Run graders (suppress JSON output, just show that it's running)
        echo "📊 Grading..."
        "$SCRIPT_DIR/grade.sh" > /dev/null

        # Show status
        echo ""
        "$0" status
        echo ""

        # Run reflection
        echo ""
        "$SCRIPT_DIR/reflect.sh"
        ;;
esac
