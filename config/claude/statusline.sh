#!/bin/bash
# Composed statusline: account identity + shared metrics + project context
# Layout: max-1 opus | $41.23 19m12s | +584/-62 | told-1699 ████████░░ 80%
# Docs: https://docs.claude.com/en/docs/claude-code/statusline

set -euo pipefail

input=$(cat)
if [ -z "$input" ]; then echo "?"; exit 0; fi

# ═══════════════════════════════════════════════════
# 1. Single jq call — extract all fields (~8ms)
# ═══════════════════════════════════════════════════
IFS=$'\t' read -r model_id cost duration_ms lines_added lines_removed cwd context_pct < <(
  echo "$input" | jq -r '[
    .model.id // "?",
    .cost.total_cost_usd // 0,
    .cost.total_duration_ms // 0,
    .cost.total_lines_added // 0,
    .cost.total_lines_removed // 0,
    (.workspace.current_dir // .cwd // "?"),
    (.context_window.used_percentage // 0 | floor)
  ] | @tsv'
)

# ═══════════════════════════════════════════════════
# 2. Account identity (from env vars, no subprocess)
# ═══════════════════════════════════════════════════
if [[ -n "${AI_ACCOUNT:-}" ]]; then
  account="$AI_ACCOUNT"
elif [[ "${ANTHROPIC_BASE_URL:-}" == *"z.ai"* ]]; then
  account="glm"
elif [[ "${ANTHROPIC_BASE_URL:-}" == *"openrouter"* ]]; then
  account="openai"
elif [[ -n "${CLAUDE_CONFIG_DIR:-}" ]]; then
  case "${CLAUDE_CONFIG_DIR##*/}" in
    .claude-max-2) account="max-2" ;;
    .claude-max-3) account="max-3" ;;
    .claude-max-4) account="max-4" ;;
    *) account="max-1" ;;
  esac
else
  account="max-1"
fi

# ═══════════════════════════════════════════════════
# 3. Model name shortening
# ═══════════════════════════════════════════════════
model_short="${model_id#claude-}"
case "$model_short" in
  opus-4-6*)     model_short="opus" ;;
  opus-4-5*)     model_short="opus-4.5" ;;
  sonnet-4-6*)   model_short="sonnet" ;;
  sonnet-4-5*)   model_short="sonnet-4.5" ;;
  sonnet-4*)     model_short="sonnet-4" ;;
  haiku-4-5*)    model_short="haiku" ;;
  *)             ;; # pass through (glm-5.1, etc.)
esac

# Detect opusplan mode (configured=opus, active=sonnet)
configured_model=$(jq -r '.model // "?"' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json" 2>/dev/null)
if [[ "$configured_model" == "opus" && "$model_short" == "sonnet" ]]; then
  model_short="opusplan"
fi

# ═══════════════════════════════════════════════════
# 4. Shared metrics formatting
# ═══════════════════════════════════════════════════
cost_fmt=$(printf '$%.2f' "$cost")

if [ "$duration_ms" -ge 3600000 ]; then
  duration_fmt="$((duration_ms / 3600000))h$((duration_ms % 3600000 / 60000))m"
elif [ "$duration_ms" -ge 60000 ]; then
  duration_fmt="$((duration_ms / 60000))m$(((duration_ms % 60000) / 1000))s"
elif [ "$duration_ms" -ge 1000 ]; then
  duration_fmt="$((duration_ms / 1000))s"
else
  duration_fmt="${duration_ms}ms"
fi

# ═══════════════════════════════════════════════════
# 5. Project context (git branch + Linear ticket)
# ═══════════════════════════════════════════════════
git_branch=""
ticket_label=""

if [ "$cwd" != "?" ] && git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  git_branch=$(git -C "$cwd" branch --show-current 2>/dev/null || echo "")

  # Extract Linear ticket from branch name (e.g., hank/told-1699-fix-thing -> told-1699)
  if [[ "$git_branch" =~ (told-[0-9]+) ]]; then
    ticket_id="${BASH_REMATCH[1]}"
    ticket_upper=$(echo "$ticket_id" | tr '[:lower:]' '[:upper:]')
    # OSC 8 clickable link (Ghostty, iTerm2, Kitty, WezTerm)
    ticket_label=$(printf '\033]8;;https://linear.app/told/issue/%s\a%s\033]8;;\a' "$ticket_upper" "$ticket_id")
  fi
fi

# ═══════════════════════════════════════════════════
# 6. Context window bar (10-char, color-coded)
# ═══════════════════════════════════════════════════
if [ "$context_pct" -ge 90 ]; then BAR_COLOR='\033[31m'    # red
elif [ "$context_pct" -ge 70 ]; then BAR_COLOR='\033[33m'  # yellow
else BAR_COLOR='\033[32m'; fi                               # green

filled=$((context_pct / 10))
empty=$((10 - filled))
printf -v fill_chars "%${filled}s" ""
printf -v empty_chars "%${empty}s" ""
bar="${fill_chars// /█}${empty_chars// /░}"

# ═══════════════════════════════════════════════════
# 7. Compose output
# ═══════════════════════════════════════════════════
CYAN='\033[36m'; YELLOW='\033[33m'; GREEN='\033[32m'; DIM='\033[2m'; RESET='\033[0m'

parts="${CYAN}${account} ${model_short}${RESET}"
parts="${parts} | ${YELLOW}${cost_fmt}${RESET} ${duration_fmt}"
parts="${parts} | +${lines_added}/-${lines_removed}"

if [ -n "$ticket_label" ]; then
  parts="${parts} | ${ticket_label}"
elif [ -n "$git_branch" ] && [ "$git_branch" != "?" ]; then
  parts="${parts} | ${GREEN}${git_branch}${RESET}"
fi

parts="${parts} ${BAR_COLOR}${bar}${RESET} ${context_pct}%"

echo -e "$parts"
