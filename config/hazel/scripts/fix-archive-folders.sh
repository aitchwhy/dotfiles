#!/usr/bin/env bash
# fix-archive-folders.sh — Fix malformed colon-separated Archive folder names
# Converts "2025:Apr:05:filename.ext" → nested "2025/Apr/05/" with file inside
# One-time script. Run with --dry-run to preview.
set -euo pipefail

ARCHIVE="$HOME/Library/CloudStorage/GoogleDrive-hank.lee.qed@gmail.com/My Drive/Archive"
DRY_RUN="${1:-}"

fixed=0
skipped=0
errors=0

echo "=== Archive Folder Fix ==="
echo "Path: $ARCHIVE"
[ "$DRY_RUN" = "--dry-run" ] && echo "MODE: DRY RUN (no changes)"
echo ""

cd "$ARCHIVE"

for dir in *; do
  # Only process directories with colons
  [ -d "$dir" ] || continue
  [[ "$dir" == *:* ]] || continue

  # Parse: "2025:Apr:05:filename.ext" → year, month, day, rest
  IFS=':' read -r year month day rest <<< "$dir"

  # Validate parsed components
  if [ -z "$year" ] || [ -z "$month" ] || [ -z "$day" ]; then
    echo "WARN: Could not parse '$dir' — skipping"
    skipped=$((skipped + 1))
    continue
  fi

  target="$year/$month/$day"

  if [ "$DRY_RUN" = "--dry-run" ]; then
    echo "[DRY RUN] $dir/ → $target/"
    fixed=$((fixed + 1))
    continue
  fi

  mkdir -p "$target"

  # Move contents of the malformed folder into the proper nested dir
  moved_any=false
  for item in "$dir"/*; do
    [ -e "$item" ] || continue
    basename="$(basename "$item")"
    if [ -e "$target/$basename" ]; then
      echo "  CONFLICT: $target/$basename exists — skipping"
      skipped=$((skipped + 1))
    else
      mv "$item" "$target/" && moved_any=true
    fi
  done

  # Also move hidden files if any
  for item in "$dir"/.[!.]*; do
    [ -e "$item" ] || continue
    basename="$(basename "$item")"
    if [ -e "$target/$basename" ]; then
      skipped=$((skipped + 1))
    else
      mv "$item" "$target/" && moved_any=true
    fi
  done

  # Remove the old colon-named directory if empty
  if rmdir "$dir" 2>/dev/null; then
    echo "Fixed: $dir/ → $target/"
    fixed=$((fixed + 1))
  else
    echo "WARN: $dir/ not empty after move"
    errors=$((errors + 1))
  fi
done

echo ""
echo "=== Summary ==="
echo "Fixed: $fixed | Skipped: $skipped | Errors: $errors"
echo ""

# Show resulting structure
echo "Top-level year directories:"
ls -d */ 2>/dev/null | grep -E '^[0-9]{4}/' || echo "(none)"
echo ""
echo "Remaining colon entries:"
ls -d *:* 2>/dev/null || echo "(none — all fixed)"
