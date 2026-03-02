#!/usr/bin/env bash
# Strip inline base64 image data from markdown files exported by
# "AI Chat Exporter" Chrome extension (and similar tools).
#
# Replaces ![alt](data:image/...;base64,...) with [Image: alt] placeholders.
# Claude can't render these inline images anyway — they just waste tokens.
#
# Usage:
#   clean-markdown-images.sh <file.md> [file2.md ...]
#   clean-markdown-images.sh --dry-run <file.md>

set -euo pipefail

dry_run=false
files=()

for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=true ;;
    --help|-h)
      echo "Usage: $(basename "$0") [--dry-run] <file.md> [file2.md ...]"
      echo ""
      echo "Strips inline base64 image data URIs from markdown files."
      echo "Replaces ![alt](data:image/...) with [Image: alt] placeholders."
      echo ""
      echo "Options:"
      echo "  --dry-run   Show what would change without modifying files"
      echo "  --help      Show this help"
      exit 0
      ;;
    *) files+=("$arg") ;;
  esac
done

if [[ ${#files[@]} -eq 0 ]]; then
  echo "Error: No files specified. Run with --help for usage." >&2
  exit 1
fi

for file in "${files[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "Error: File not found: $file" >&2
    continue
  fi

  before=$(wc -c < "$file")
  write_flag="$( $dry_run && echo "false" || echo "true" )"

  python3 - "$file" "$write_flag" << 'PYEOF'
import re, sys

filepath = sys.argv[1]
should_write = sys.argv[2] == "true"

with open(filepath, "r") as f:
    content = f.read()

pattern = r"!\[([^\]]*)\]\(data:image/[^)]+\)"
matches = list(re.finditer(pattern, content))

if not matches:
    print("  No base64 images found")
    raise SystemExit(0)

cleaned = re.sub(
    pattern,
    lambda m: f"[Image: {m.group(1) or 'unnamed'}]",
    content,
)

for m in matches:
    line = content[: m.start()].count("\n") + 1
    print(f"  Line {line}: {m.group(1) or 'unnamed'} ({len(m.group(0)):,} chars)")

if should_write:
    with open(filepath, "w") as f:
        f.write(cleaned)

after = len(cleaned.encode("utf-8"))
saved = len(content.encode("utf-8")) - after
pct = saved * 100 // len(content.encode("utf-8"))
suffix = "" if should_write else " (dry run, no changes made)"
print()
print(f"{filepath}: {len(content.encode('utf-8')):,} bytes -> {after:,} bytes (saved {saved:,} bytes, {pct}%){suffix}")
PYEOF
done
