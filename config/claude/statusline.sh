#!/bin/bash
# Claude Code custom statusline
# Receives JSON on stdin, prints formatted status line to stdout.
# Docs: https://docs.claude.com/en/docs/claude-code/statusline

set -euo pipefail

# Read JSON input from stdin (Claude Code pipes this on every update)
input=$(cat)

# Guard: empty stdin would cause jq parse error, killing script under set -e
if [ -z "$input" ]; then
  echo "?"
  exit 0
fi

# Single jq invocation: extract all fields at once (~8ms vs ~35-70ms for 7 calls)
# Output format: model_id TAB cost TAB duration_ms TAB lines_added TAB lines_removed TAB cwd
# Explicit IFS for tab-delimited @tsv output from jq
IFS=$'\t' read -r model_id cost duration_ms lines_added lines_removed cwd < <(
  echo "$input" | jq -r '[.model.id // "?", .cost.total_cost_usd // 0, .cost.total_duration_ms // 0, .cost.total_lines_added // 0, .cost.total_lines_removed // 0, (.workspace.current_dir // .cwd // "?")] | @tsv'
)

# Format cost as $X.XX
cost_formatted=$(printf '$%.2f' "$cost")

# Format duration
if [ "$duration_ms" -ge 60000 ]; then
  duration_formatted="$((duration_ms / 60000))m$(((duration_ms % 60000) / 1000))s"
elif [ "$duration_ms" -ge 1000 ]; then
  duration_formatted="$((duration_ms / 1000))s"
else
  duration_formatted="${duration_ms}ms"
fi

# Git info (run in cwd of the Claude Code session)
git_branch=""
pr_url=""

if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  git_branch=$(git -C "$cwd" branch --show-current 2>/dev/null || echo "?")

  # PR lookup with caching (60s TTL)
  # Cache is scoped by cwd hash + branch to prevent thrashing across concurrent sessions
  cwd_hash=$(printf '%s' "$cwd" | cksum | cut -d' ' -f1)
  cache_file="/tmp/claude-statusline-pr-cache-${cwd_hash}-${git_branch}"
  cache_ttl=60
  if [ -f "$cache_file" ] && [ "$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0)))" -lt "$cache_ttl" ]; then
    pr_url=$(cat "$cache_file" 2>/dev/null || echo "")
  else
    # Derive repo slug from git remote so gh pr view works regardless of cwd
    gh_repo=$(git -C "$cwd" remote get-url origin 2>/dev/null | sed -E 's|.*github.com[:/]([^/]+/[^.]+)(\.git)?|\1|' || echo "")
    if [ -n "$gh_repo" ]; then
      pr_url=$(gh pr view -R "$gh_repo" --json url -q .url 2>/dev/null || echo "")
    else
      pr_url=$(cd "$cwd" && gh pr view --json url -q .url 2>/dev/null || echo "")
    fi
    # Atomic write: write to temp file, then mv (atomic on same filesystem)
    printf '%s' "$pr_url" > "${cache_file}.tmp" 2>/dev/null && mv -f "${cache_file}.tmp" "$cache_file" 2>/dev/null || true
  fi
fi

# Build output with ANSI colors
# Cyan=model, Yellow=cost, Green=branch, Dim=PR
CYAN='\033[36m'
YELLOW='\033[33m'
GREEN='\033[32m'
DIM='\033[2m'
RESET='\033[0m'

parts=""
parts="${parts}${CYAN}${model_id}${RESET}"
parts="${parts} | ${YELLOW}${cost_formatted}${RESET} ${duration_formatted}"
parts="${parts} | +${lines_added}/-${lines_removed}"

if [ -n "$git_branch" ] && [ "$git_branch" != "?" ]; then
  parts="${parts} | ${GREEN}${git_branch}${RESET}"
fi

if [ -n "$pr_url" ]; then
  parts="${parts} ${DIM}${pr_url}${RESET}"
fi

echo -e "$parts"
