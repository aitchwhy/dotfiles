#!/usr/bin/env bash
# check-agents-drift.sh — Detect AGENTS.md vs CLAUDE.md structural drift
# Run from dotfiles repo root: bash config/quality/scripts/check-agents-drift.sh

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
TOLD_DIR="${TOLD_DIR:-$HOME/src/told}"
MAX_SIZE=32768  # 32 KiB Codex limit
ERRORS=0

red() { printf '\033[0;31m%s\033[0m\n' "$1"; }
green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$1"; }

check_exists() {
  local repo="$1" file="$2"
  if [ ! -f "$repo/$file" ]; then
    red "FAIL: $repo/$file does not exist"
    ERRORS=$((ERRORS + 1))
    return 1
  fi
  return 0
}

check_size() {
  local file="$1"
  local size
  size=$(wc -c < "$file")
  if [ "$size" -gt "$MAX_SIZE" ]; then
    red "FAIL: $file is ${size} bytes (limit: ${MAX_SIZE})"
    ERRORS=$((ERRORS + 1))
  else
    green "OK: $file is ${size} bytes (under ${MAX_SIZE} limit)"
  fi
}

check_sections() {
  local repo_name="$1" agents="$2" claude="$3"
  # Extract ## headings from AGENTS.md (skip Claude-only boundary section)
  local agents_sections
  agents_sections=$(grep -E '^## ' "$agents" | grep -v 'Claude Code vs Codex' | sed 's/^## //' | sort)

  local missing=0
  while IFS= read -r section; do
    if ! grep -qF "## $section" "$claude"; then
      yellow "WARN: $repo_name AGENTS.md section '## $section' has no match in CLAUDE.md"
      missing=$((missing + 1))
    fi
  done <<< "$agents_sections"

  if [ "$missing" -eq 0 ]; then
    green "OK: $repo_name — all AGENTS.md sections found in CLAUDE.md"
  fi
}

check_stack_versions() {
  local repo_name="$1" agents="$2" claude="$3"
  # Extract first column (component name) from AGENTS.md stack table
  # Check each AGENTS.md entry exists in CLAUDE.md (subset check, not exact match)
  local agents_components
  agents_components=$(awk '/^## Stack/,/^## [^S]/' "$agents" \
    | grep -F '|' | grep -Fv -- '---' | grep -Fv 'Component' | grep -Fv 'Category' \
    | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' | sort)

  if [ -z "$agents_components" ]; then
    yellow "WARN: $repo_name AGENTS.md has no stack table rows"
    return
  fi

  local missing=0
  while IFS= read -r component; do
    [ -z "$component" ] && continue
    if ! grep -Fq "$component" "$claude"; then
      yellow "WARN: $repo_name — AGENTS.md component '$component' not found in CLAUDE.md"
      missing=$((missing + 1))
    fi
  done <<< "$agents_components"

  if [ "$missing" -eq 0 ]; then
    green "OK: $repo_name — all AGENTS.md stack entries present in CLAUDE.md"
  else
    ERRORS=$((ERRORS + missing))
  fi
}

echo "=== AGENTS.md Drift Check ==="
echo ""

# 1. File existence
echo "--- File Existence ---"
dotfiles_agents=0
dotfiles_claude=0
told_agents=0
told_claude=0

check_exists "$DOTFILES_DIR" "AGENTS.md" && dotfiles_agents=1
check_exists "$DOTFILES_DIR" "CLAUDE.md" && dotfiles_claude=1
check_exists "$TOLD_DIR" "AGENTS.md" && told_agents=1
check_exists "$TOLD_DIR" "CLAUDE.md" && told_claude=1
echo ""

# 2. Size checks
echo "--- Size Check (32 KiB limit) ---"
[ "$dotfiles_agents" -eq 1 ] && check_size "$DOTFILES_DIR/AGENTS.md"
[ "$told_agents" -eq 1 ] && check_size "$TOLD_DIR/AGENTS.md"
echo ""

# 3. Section header alignment
echo "--- Section Headers ---"
if [ "$dotfiles_agents" -eq 1 ] && [ "$dotfiles_claude" -eq 1 ]; then
  check_sections "dotfiles" "$DOTFILES_DIR/AGENTS.md" "$DOTFILES_DIR/CLAUDE.md"
fi
if [ "$told_agents" -eq 1 ] && [ "$told_claude" -eq 1 ]; then
  check_sections "told" "$TOLD_DIR/AGENTS.md" "$TOLD_DIR/CLAUDE.md"
fi
echo ""

# 4. Stack version alignment
echo "--- Stack Versions ---"
if [ "$dotfiles_agents" -eq 1 ] && [ "$dotfiles_claude" -eq 1 ]; then
  check_stack_versions "dotfiles" "$DOTFILES_DIR/AGENTS.md" "$DOTFILES_DIR/CLAUDE.md"
fi
if [ "$told_agents" -eq 1 ] && [ "$told_claude" -eq 1 ]; then
  check_stack_versions "told" "$TOLD_DIR/AGENTS.md" "$TOLD_DIR/CLAUDE.md"
fi
echo ""

# Summary
echo "=== Summary ==="
if [ "$ERRORS" -eq 0 ]; then
  green "All checks passed."
else
  red "$ERRORS issue(s) found. See drift-governance.md for recovery steps."
  exit 1
fi
