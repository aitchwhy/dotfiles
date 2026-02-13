#!/usr/bin/env bash
# cleanup-documents.sh — Move app folders from ~/Documents to Google Drive Backups
# One-time interactive script. Run with --dry-run to preview.
set -euo pipefail

DOCS="$HOME/Documents"
BACKUPS="$HOME/Library/CloudStorage/GoogleDrive-hank.lee.qed@gmail.com/My Drive/Backups"
DRY_RUN="${1:-}"

# Folders to keep in Documents (active, evergreen)
KEEP=("Hayaeh" "Therapy" "Told")

# Mapping: source_folder → destination_folder
# For merges (destination exists), contents are moved in; conflicts are skipped
declare -A MOVES=(
  ["Blender"]="Blender"
  ["Cursor"]="Cursor"
  ["Downie"]="Downie"
  ["Fathom"]="Fathom-Videos"
  ["Granola"]="Granola"
  ["Kiwix-wikipedia-offline"]="Kiwix-Wikipedia"
  ["Leasy"]="Leasy"
  ["PDFs"]="PDFs"
  ["Polycam"]="Polycam"
  ["Signet"]="Signet"
  ["Tana"]="Tana"
  ["Whisper"]="Whisper"
  ["Zoom"]="Zoom"
)

# Folders to delete
DELETE=("JCY")

moved=0
skipped=0
deleted=0
errors=0

echo "=== Documents Cleanup ==="
echo "Source: $DOCS"
echo "Destination: $BACKUPS"
[ "$DRY_RUN" = "--dry-run" ] && echo "MODE: DRY RUN (no changes)"
echo ""

# Move mapped folders
for src in "${!MOVES[@]}"; do
  dst="${MOVES[$src]}"
  src_path="$DOCS/$src"
  dst_path="$BACKUPS/$dst"

  if [ ! -d "$src_path" ]; then
    echo "SKIP: $src (not found)"
    skipped=$((skipped + 1))
    continue
  fi

  if [ "$DRY_RUN" = "--dry-run" ]; then
    if [ -d "$dst_path" ]; then
      echo "[DRY RUN] MERGE: $src/ → Backups/$dst/ (destination exists)"
    else
      echo "[DRY RUN] MOVE:  $src/ → Backups/$dst/"
    fi
    continue
  fi

  if [ -d "$dst_path" ]; then
    # Merge: move contents into existing folder, skip conflicts
    echo "MERGE: $src/ → Backups/$dst/"
    for item in "$src_path"/*; do
      [ -e "$item" ] || continue
      basename="$(basename "$item")"
      if [ -e "$dst_path/$basename" ]; then
        echo "  CONFLICT (skipped): $basename already exists in destination"
        skipped=$((skipped + 1))
      else
        mv "$item" "$dst_path/" && echo "  Moved: $basename"
      fi
    done
    # Remove source if empty
    rmdir "$src_path" 2>/dev/null && echo "  Removed empty: $src/" || echo "  WARN: $src/ not empty after merge"
  else
    # Simple move
    mv "$src_path" "$dst_path" && echo "MOVE: $src/ → Backups/$dst/"
  fi
  moved=$((moved + 1))
done

echo ""

# Delete specified folders
for dir in "${DELETE[@]}"; do
  dir_path="$DOCS/$dir"
  if [ ! -d "$dir_path" ]; then
    echo "SKIP: $dir (not found, nothing to delete)"
    continue
  fi

  if [ "$DRY_RUN" = "--dry-run" ]; then
    echo "[DRY RUN] DELETE: $dir/"
    continue
  fi

  rm -rf "$dir_path" && echo "DELETE: $dir/"
  deleted=$((deleted + 1))
done

echo ""

# Move loose files to Backups/Loose-Files/
echo "--- Loose files ---"
loose_dst="$BACKUPS/Loose-Files"

for item in "$DOCS"/*; do
  [ -e "$item" ] || continue
  basename="$(basename "$item")"

  # Skip directories (handled above or kept)
  [ -d "$item" ] && continue

  # Skip .DS_Store
  [ "$basename" = ".DS_Store" ] && continue

  if [ "$DRY_RUN" = "--dry-run" ]; then
    echo "[DRY RUN] MOVE: $basename → Backups/Loose-Files/"
    continue
  fi

  mkdir -p "$loose_dst"
  if [ -e "$loose_dst/$basename" ]; then
    echo "CONFLICT (skipped): $basename already in Loose-Files/"
    skipped=$((skipped + 1))
  else
    mv "$item" "$loose_dst/" && echo "MOVE: $basename → Backups/Loose-Files/"
    moved=$((moved + 1))
  fi
done

echo ""
echo "=== Summary ==="
echo "Moved: $moved | Deleted: $deleted | Skipped: $skipped | Errors: $errors"
echo ""

# Show what remains
echo "Remaining in ~/Documents/:"
ls "$DOCS" 2>/dev/null || echo "(empty)"
