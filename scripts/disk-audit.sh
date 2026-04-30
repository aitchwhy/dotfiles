#!/usr/bin/env bash
# Disk audit — read-only inventory of host-side storage.
#
# Surfaces the categories that drove CC-58 (macbook 90% disk):
#   1. Root filesystem usage (`df -h /`)
#   2. iOS device backups (iMazing + Finder MobileSync)
#   3. Google Drive mirror (size + top-level folder breakdown)
#   4. Photos library
#   5. Desktop loose files
#   6. Worktrees (~/told-worktrees, ~/src/told git worktrees)
#   7. Homebrew cache
#   8. App-specific caches (MacWhisper, Claude Desktop, Paste)
#
# This script never deletes. It writes a dated markdown report under
# audit-reports/disk/<UTC-date>.md and prints recommendations.
#
# Flags:
#   --report PATH         override report path
#   --no-recommendations  suppress Recommendations section (diff-friendly snapshots)

set -uo pipefail

REPORT_DIR="$HOME/dotfiles/audit-reports/disk"
REPORT="$REPORT_DIR/$(date -u +%Y-%m-%d).md"
RECOMMEND=1

while [ $# -gt 0 ]; do
  case "$1" in
    --report) REPORT="$2"; shift 2 ;;
    --no-recommendations) RECOMMEND=0; shift ;;
    *) echo "Unknown flag: $1" >&2; exit 2 ;;
  esac
done

mkdir -p "$(dirname "$REPORT")"

# Findings tally — bucketed by ALERT/WARN, drives Recommendations
TALLY="$(mktemp -t disk-audit-tally.XXXXXX)"
echo "0 0" > "$TALLY"  # alert warn
RECS="$(mktemp -t disk-audit-recs.XXXXXX)"
trap 'rm -f "$TALLY" "$RECS"' EXIT

bump() {
  read -r a w < "$TALLY"
  case "$1" in
    ALERT) a=$((a+1)) ;;
    WARN)  w=$((w+1)) ;;
  esac
  echo "$a $w" > "$TALLY"
}

emit() { printf '%s\n' "$@" >> "$REPORT"; }
section() { emit "" "## $1" ""; }
recommend() { printf -- '- %s\n' "$1" >> "$RECS"; }

# Tolerant size: returns "?" on permission/missing errors instead of stalling.
size_of() {
  local path="$1"
  if [ ! -e "$path" ]; then
    echo "—"
    return
  fi
  du -sh "$path" 2>/dev/null | cut -f1 || echo "?"
}

cat > "$REPORT" <<EOF
# Disk audit — $(date -u +%Y-%m-%dT%H:%M:%SZ)

Host: $(hostname -s)
Trigger: \`$(basename "${0}")\`

> Read-only inventory. This script does not delete anything — review the
> Recommendations section and act with the cited commands or GUI flows.
EOF

# ─────────────────────────────────────────────────────────────────────────────
# 1. Root filesystem
# ─────────────────────────────────────────────────────────────────────────────
section "1. Root filesystem (df -h /)"

DF_LINE="$(df -h / | awk 'NR==2')"
DF_PCT="$(echo "$DF_LINE" | awk '{print $5}' | tr -d '%')"
emit '```'
df -h / >> "$REPORT"
emit '```'

if [ -n "$DF_PCT" ] && [ "$DF_PCT" -ge 90 ] 2>/dev/null; then
  emit ""
  emit "🚨 ALERT: root filesystem at ${DF_PCT}% — under 10% free."
  bump ALERT
  recommend "Disk at ${DF_PCT}%. Run sections 2-5 of CC-58 playbook (iOS backups, Drive stream, Photos optimize, brew cleanup)."
elif [ -n "$DF_PCT" ] && [ "$DF_PCT" -ge 80 ] 2>/dev/null; then
  emit ""
  emit "⚠️  WARN: root filesystem at ${DF_PCT}% — plan cleanup."
  bump WARN
  recommend "Disk at ${DF_PCT}%. Consider \`bclean\` and \`clean\` (nix-collect-garbage) before it crosses 90%."
fi

# ─────────────────────────────────────────────────────────────────────────────
# 2. iOS backups
# ─────────────────────────────────────────────────────────────────────────────
section "2. iOS backups"

IMAZING_DIR="$HOME/Library/Application Support/iMazing/Backups"
MOBILESYNC_DIR="$HOME/Library/Application Support/MobileSync/Backup"

emit "| Path | Size |"
emit "|---|---|"
emit "| \`~/Library/Application Support/iMazing/Backups\` | $(size_of "$IMAZING_DIR") |"
emit "| \`~/Library/Application Support/MobileSync/Backup\` | $(size_of "$MOBILESYNC_DIR") |"

# Per-device UDID breakdown when present
for parent in "$IMAZING_DIR" "$MOBILESYNC_DIR"; do
  if [ -d "$parent" ]; then
    emit ""
    emit "**${parent/$HOME/~}** per-device:"
    emit '```'
    du -sh "$parent"/*/ 2>/dev/null | sort -hr >> "$REPORT" || true
    emit '```'
  fi
done

# Threshold: >50 GB total iOS backups → ALERT (iCloud Backup is the canonical replacement)
IMAZING_BYTES=0
MOBILESYNC_BYTES=0
[ -d "$IMAZING_DIR" ]    && IMAZING_BYTES=$(du -sk "$IMAZING_DIR" 2>/dev/null | awk '{print $1}' || echo 0)
[ -d "$MOBILESYNC_DIR" ] && MOBILESYNC_BYTES=$(du -sk "$MOBILESYNC_DIR" 2>/dev/null | awk '{print $1}' || echo 0)
IOS_TOTAL_KB=$((IMAZING_BYTES + MOBILESYNC_BYTES))
if [ "$IOS_TOTAL_KB" -gt 52428800 ]; then  # 50 GB in KB
  emit ""
  emit "🚨 ALERT: iOS backups exceed 50 GB locally."
  bump ALERT
  recommend "iOS backups >50 GB locally. Verify each device's iCloud Backup is current (Settings → iCloud → iCloud Backup), then delete via Finder (MobileSync) or iMazing GUI."
  recommend "Consider uninstalling iMazing (\`brew uninstall --cask imazing\` if installed) — iCloud Backup covers the same role."
fi

# ─────────────────────────────────────────────────────────────────────────────
# 3. Google Drive mirror
# ─────────────────────────────────────────────────────────────────────────────
section "3. Google Drive mirror"

# Drive's actual on-disk path on this host (CloudStorage virtual mount)
GDRIVE_ROOT="$HOME/Library/CloudStorage/GoogleDrive-hank.lee.qed@gmail.com/My Drive"

if ! pgrep -x "Google Drive" >/dev/null 2>&1; then
  emit "ℹ️  Google Drive process not running — skipping size measurement (would be unreliable)."
elif [ ! -d "$GDRIVE_ROOT" ]; then
  emit "ℹ️  Drive mount not present at expected path."
  emit ""
  emit "Expected: \`${GDRIVE_ROOT/$HOME/~}\`"
else
  GDRIVE_SIZE="$(size_of "$GDRIVE_ROOT")"
  emit "Total: **$GDRIVE_SIZE**"
  emit ""
  emit "Top-level subfolders:"
  emit '```'
  du -sh "$GDRIVE_ROOT"/*/ 2>/dev/null | sort -hr | head -20 >> "$REPORT" || true
  emit '```'

  # Flag any single subfolder >100 GB (signals an "Available offline" mistake)
  BIG_FOLDERS="$(du -sk "$GDRIVE_ROOT"/*/ 2>/dev/null \
    | awk '$1 > 104857600 {print}' \
    | sort -nr)"
  if [ -n "$BIG_FOLDERS" ]; then
    emit ""
    emit "🚨 ALERT: subfolders >100 GB local (likely \"Available offline\" mistake):"
    emit '```'
    echo "$BIG_FOLDERS" >> "$REPORT"
    emit '```'
    bump ALERT
    recommend "Drive subfolder(s) >100 GB local. In Finder, right-click each → \"Online only\" to evict from local cache. Verify retention policy in config/hazel/CLAUDE.md."
  fi

  # Total local Drive >200 GB → WARN (post-stream target is <200 GB per CC-58)
  GDRIVE_KB=$(du -sk "$GDRIVE_ROOT" 2>/dev/null | awk '{print $1}' || echo 0)
  if [ "$GDRIVE_KB" -gt 209715200 ]; then  # 200 GB in KB
    emit ""
    emit "⚠️  WARN: Drive local cache >200 GB — Stream mode goal is <200 GB."
    bump WARN
    recommend "Drive local cache >200 GB. Confirm Drive is in Stream mode (Drive menu bar → Preferences → \"Stream files\")."
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# 4. Photos library
# ─────────────────────────────────────────────────────────────────────────────
section "4. Photos library"

PHOTOS_DIR="$HOME/Pictures"
PHOTOS_LIB="$HOME/Pictures/Photos Library.photoslibrary"
emit "\`~/Pictures\`: $(size_of "$PHOTOS_DIR")"
if [ -d "$PHOTOS_LIB" ]; then
  emit ""
  emit "\`Photos Library.photoslibrary\`: $(size_of "$PHOTOS_LIB")"
fi

PHOTOS_KB=0
[ -d "$PHOTOS_DIR" ] && PHOTOS_KB=$(du -sk "$PHOTOS_DIR" 2>/dev/null | awk '{print $1}' || echo 0)
if [ "$PHOTOS_KB" -gt 104857600 ]; then  # 100 GB
  emit ""
  emit "⚠️  WARN: Photos >100 GB — consider \"Optimize Mac Storage\"."
  bump WARN
  recommend "Photos library >100 GB. Photos.app → Settings → iCloud → enable \"Optimize Mac Storage\" (reversible)."
fi

# ─────────────────────────────────────────────────────────────────────────────
# 5. Desktop
# ─────────────────────────────────────────────────────────────────────────────
section "5. Desktop"

DESKTOP_DIR="$HOME/Desktop"
emit "\`~/Desktop\`: $(size_of "$DESKTOP_DIR")"
DESKTOP_KB=0
[ -d "$DESKTOP_DIR" ] && DESKTOP_KB=$(du -sk "$DESKTOP_DIR" 2>/dev/null | awk '{print $1}' || echo 0)
if [ "$DESKTOP_KB" -gt 5242880 ]; then  # 5 GB
  emit ""
  emit "⚠️  WARN: Desktop >5 GB. Hazel Documents-archival rule should cover this if running."
  bump WARN
  recommend "Desktop >5 GB. Verify Hazel is running and rules are firing (\`pgrep -x Hazel\`). Manual sweep: sort screenshots → ~/Pictures/Screenshots, PDFs → ~/Documents."
fi

# ─────────────────────────────────────────────────────────────────────────────
# 6. Worktrees
# ─────────────────────────────────────────────────────────────────────────────
section "6. Worktrees"

if [ -d "$HOME/told-worktrees" ]; then
  emit "**\`~/told-worktrees\`**: $(size_of "$HOME/told-worktrees")"
  emit '```'
  du -sh "$HOME/told-worktrees"/*/ 2>/dev/null | sort -hr >> "$REPORT" || true
  emit '```'
fi

# Avatar / dotfiles worktrees if any
for wt_root in "$HOME/avatar-worktrees" "$HOME/dotfiles-worktrees"; do
  if [ -d "$wt_root" ] && [ -n "$(ls -A "$wt_root" 2>/dev/null)" ]; then
    emit ""
    emit "**\`${wt_root/$HOME/~}\`**: $(size_of "$wt_root")"
    emit '```'
    du -sh "$wt_root"/*/ 2>/dev/null | sort -hr >> "$REPORT" || true
    emit '```'
  fi
done

if command -v git >/dev/null 2>&1 && [ -d "$HOME/src/told/.git" ]; then
  emit ""
  emit "**\`~/src/told\` git worktrees:**"
  emit '```'
  git -C "$HOME/src/told" worktree list 2>/dev/null >> "$REPORT" || true
  emit '```'
fi

# ─────────────────────────────────────────────────────────────────────────────
# 7. Homebrew cache
# ─────────────────────────────────────────────────────────────────────────────
section "7. Homebrew cache"

if command -v brew >/dev/null 2>&1; then
  BREW_CACHE="$(brew --cache 2>/dev/null || true)"
  if [ -n "$BREW_CACHE" ] && [ -d "$BREW_CACHE" ]; then
    emit "\`$BREW_CACHE\`: $(size_of "$BREW_CACHE")"
    BREW_KB=$(du -sk "$BREW_CACHE" 2>/dev/null | awk '{print $1}' || echo 0)
    if [ "$BREW_KB" -gt 5242880 ]; then  # 5 GB
      emit ""
      emit "⚠️  WARN: brew cache >5 GB."
      bump WARN
      recommend "Brew cache >5 GB. Run \`bclean\` (alias for \`brew cleanup --prune=all && rm -rf \$(brew --cache) && brew autoremove\`)."
    fi
  else
    emit "ℹ️  \`brew --cache\` returned no path."
  fi
else
  emit "ℹ️  Homebrew not on PATH."
fi

# ─────────────────────────────────────────────────────────────────────────────
# 8. App-specific caches
# ─────────────────────────────────────────────────────────────────────────────
section "8. App-specific caches"

emit "| Path | Size |"
emit "|---|---|"
APP_PATHS=(
  "$HOME/Library/Containers/com.goodsnooze.MacWhisper"
  "$HOME/Library/Application Support/Claude"
  "$HOME/Library/Application Support/com.wiheads.paste-setapp"
)
for p in "${APP_PATHS[@]}"; do
  emit "| \`${p/$HOME/~}\` | $(size_of "$p") |"
done

# Top 5 entries under ~/Library/Caches
if [ -d "$HOME/Library/Caches" ]; then
  emit ""
  emit "Top 5 \`~/Library/Caches\` entries:"
  emit '```'
  du -sh "$HOME/Library/Caches"/* 2>/dev/null | sort -hr | head -5 >> "$REPORT" || true
  emit '```'
fi

# Per-app threshold: >10 GB → WARN
for p in "${APP_PATHS[@]}"; do
  if [ -d "$p" ]; then
    KB=$(du -sk "$p" 2>/dev/null | awk '{print $1}' || echo 0)
    if [ "$KB" -gt 10485760 ]; then  # 10 GB
      bump WARN
      recommend "\`${p/$HOME/~}\` >10 GB. Cap retention in app preferences (Paste, MacWhisper, Claude Desktop)."
    fi
  fi
done

# ─────────────────────────────────────────────────────────────────────────────
# Recommendations
# ─────────────────────────────────────────────────────────────────────────────
read -r ALERTS WARNS < "$TALLY"

if [ "$RECOMMEND" = 1 ]; then
  section "Recommendations"
  if [ -s "$RECS" ]; then
    cat "$RECS" >> "$REPORT"
  else
    emit "No threshold breaches. Disk hygiene OK."
  fi
fi

# Always-on housekeeping
if [ "$RECOMMEND" = 1 ]; then
  emit ""
  emit "**Always-safe routine cleanup** (run any time):"
  emit ""
  emit "- \`bclean\` — brew cleanup + cache prune + autoremove"
  emit "- \`clean\` — nix-collect-garbage -d"
  emit "- \`just disk-audit\` again in 30 days"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────
section "Summary"
emit "| Severity | Count |"
emit "|---|---|"
emit "| ALERT | $ALERTS |"
emit "| WARN  | $WARNS |"
emit ""

printf '\n'
printf 'Disk audit: %d ALERT · %d WARN\n' "$ALERTS" "$WARNS"
printf 'Report: %s\n' "$REPORT"
printf '✓ Audit complete (read-only — review report and act on recommendations).\n'
