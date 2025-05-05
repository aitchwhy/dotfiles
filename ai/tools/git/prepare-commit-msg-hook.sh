#!/usr/bin/env bash
# AI-assisted commit message hook
# Version: 1.0.0 (May 2025)
#
# This prepare-commit-msg hook enhances commit messages using AI,
# following conventional commits format and ensuring quality.

# Exit on error
set -e

# Get hook arguments
COMMIT_MSG_FILE="$1"
COMMIT_SOURCE="$2"
SHA1="$3"

# Load core utilities
AI_CONFIG_DIR="${AI_CONFIG_DIR:-${HOME}/.config/ai}"
source "${AI_CONFIG_DIR}/core/constants.sh" 2>/dev/null || {
  echo "Error: Could not load AI core constants"
  exit 1
}
source "${AI_CONFIG_DIR}/core/utils.sh" 2>/dev/null || {
  echo "Error: Could not load AI core utilities"
  exit 1
}

# Skip for specific commit sources
if [ "$COMMIT_SOURCE" = "merge" ] || [ "$COMMIT_SOURCE" = "squash" ] || [ "$COMMIT_SOURCE" = "commit" ]; then
  ai_log "info" "Skipping AI commit message for $COMMIT_SOURCE"
  exit 0
fi

# Check if AI commit message generation is enabled
if [ "${AI_GIT_AI_ASSISTED_COMMIT:-1}" -ne 1 ]; then
  ai_log "info" "AI commit message assistance is disabled"
  exit 0
fi

# Check if we have an api key for the default provider
if ! ai_validate_provider_auth "$AI_DEFAULT_PROVIDER"; then
  ai_log "warn" "No API key for $AI_DEFAULT_PROVIDER, skipping AI commit message"
  exit 0
fi

ai_log "info" "Running AI commit message hook"

# Check if current message is already following conventional format
CURRENT_MSG=$(cat "$COMMIT_MSG_FILE" | grep -v "^#")
if echo "$CURRENT_MSG" | grep -qE "^(feat|fix|docs|style|refactor|perf|test|build|ci|chore)(\([a-z0-9_-]+\))?!?: .+"; then
  ai_log "info" "Commit message already follows conventional format"
  exit 0
fi

# Get the diff to analyze
DIFF=$(git diff --staged)

# Skip if there's no diff
if [ -z "$DIFF" ]; then
  ai_log "warn" "No staged changes, skipping AI commit message"
  exit 0
fi

# Get git status for additional context
STATUS=$(git status --short)

# Get model to use for commit message
MODEL=$(ai_get_default_model "commit")
ai_log "info" "Using model: $MODEL for commit message"

# Create temporary file for AI response
TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT

# Generate commit message with AI
if ai_command_exists "claude"; then
  # Use Claude CLI if available
  PROMPT="Generate a concise, informative git commit message for the following changes. 
Follow the Conventional Commits specification (https://www.conventionalcommits.org/).
Format: <type>(<scope>): <description>

Types: feat, fix, docs, style, refactor, test, chore, perf, build, ci
Scope is optional but should indicate the component being changed
Description should be present tense, lowercase, no period at end

STAGED CHANGES:
$DIFF

STATUS:
$STATUS

Respond ONLY with the commit message, nothing else."

  claude --message "$PROMPT" --model "$MODEL" --max-tokens 100 > "$TEMP_FILE"
  
elif ai_command_exists "curl" && [ -n "$ANTHROPIC_API_KEY" ]; then
  # Fallback to direct API call if Claude CLI not available
  PROMPT="Generate a concise, informative git commit message for the following changes. 
Follow the Conventional Commits specification (https://www.conventionalcommits.org/).
Format: <type>(<scope>): <description>

Types: feat, fix, docs, style, refactor, test, chore, perf, build, ci
Scope is optional but should indicate the component being changed
Description should be present tense, lowercase, no period at end

STAGED CHANGES:
$DIFF

STATUS:
$STATUS

Respond ONLY with the commit message, nothing else."

  # Construct API request
  REQUEST_BODY=$(cat <<EOF
{
  "model": "$MODEL",
  "max_tokens": 100,
  "temperature": 0.2,
  "messages": [
    {
      "role": "user",
      "content": "$PROMPT"
    }
  ]
}
EOF
)

  # Make API request
  curl -s -X POST "$AI_ENDPOINT_ANTHROPIC" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -d "$REQUEST_BODY" | jq -r '.content[0].text' > "$TEMP_FILE"
  
else
  ai_log "warn" "No Claude CLI or API available, skipping AI commit message"
  exit 0
fi

# Get AI response
AI_MSG=$(cat "$TEMP_FILE")

# Validate AI-generated message
if [ -z "$AI_MSG" ]; then
  ai_log "error" "Failed to generate commit message with AI"
  exit 1
fi

# Check if AI message follows conventional format
if ! echo "$AI_MSG" | grep -qE "^(feat|fix|docs|style|refactor|perf|test|build|ci|chore)(\([a-z0-9_-]+\))?!?: .+"; then
  ai_log "warn" "AI-generated message doesn't follow conventional format, using as-is"
fi

# If the user has entered a message already, offer to combine/replace
if [ -n "$CURRENT_MSG" ] && [ "$CURRENT_MSG" != "$(cat "$COMMIT_MSG_FILE" | grep "^#")" ]; then
  ai_log "info" "Existing commit message found"
  ai_log "info" "Original message: $CURRENT_MSG"
  ai_log "info" "AI suggestion: $AI_MSG"
  
  # Prompt for user choice if interactive terminal
  if [ -t 0 ]; then
    echo -e "${AI_COLOR_CYAN}Existing commit message:${AI_COLOR_RESET} $CURRENT_MSG"
    echo -e "${AI_COLOR_CYAN}AI-suggested message:${AI_COLOR_RESET} $AI_MSG"
    echo ""
    echo -e "${AI_COLOR_YELLOW}Choose an option:${AI_COLOR_RESET}"
    echo "  1) Keep existing message"
    echo "  2) Use AI-suggested message"
    echo "  3) Combine messages"
    echo "  4) Edit AI-suggested message"
    read -p "Your choice [2]: " CHOICE
    
    case "${CHOICE:-2}" in
      1)
        ai_log "info" "Keeping existing message"
        exit 0
        ;;
      2)
        ai_log "info" "Using AI-suggested message"
        echo "$AI_MSG" > "$COMMIT_MSG_FILE"
        ;;
      3)
        ai_log "info" "Combining messages"
        echo "$AI_MSG" > "$COMMIT_MSG_FILE"
        echo "" >> "$COMMIT_MSG_FILE"
        echo "Original message: $CURRENT_MSG" >> "$COMMIT_MSG_FILE"
        ;;
      4)
        ai_log "info" "Editing AI-suggested message"
        echo "$AI_MSG" > "$COMMIT_MSG_FILE.ai"
        ${EDITOR:-vim} "$COMMIT_MSG_FILE.ai"
        cat "$COMMIT_MSG_FILE.ai" > "$COMMIT_MSG_FILE"
        rm -f "$COMMIT_MSG_FILE.ai"
        ;;
      *)
        ai_log "info" "Using AI-suggested message"
        echo "$AI_MSG" > "$COMMIT_MSG_FILE"
        ;;
    esac
  else
    # Non-interactive mode - use AI message by default
    echo "$AI_MSG" > "$COMMIT_MSG_FILE"
  fi
else
  # No existing message, use AI message
  echo "$AI_MSG" > "$COMMIT_MSG_FILE"
fi

ai_log "info" "AI commit message hook completed successfully"
exit 0