#!/usr/bin/env bash
# Install Git hooks for AI integration
# Version: 1.0.0 (May 2025)

# Exit on error
set -e

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

ai_log "info" "Installing Git hooks for AI integration"

# Determine git repository root
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  REPO_ROOT=$(git rev-parse --show-toplevel)
  ai_log "info" "Git repository found at: $REPO_ROOT"
else
  ai_log "error" "Not inside a git repository"
  exit 1
fi

# Create hooks directory if it doesn't exist
HOOKS_DIR="$REPO_ROOT/.git/hooks"
mkdir -p "$HOOKS_DIR"

# Install pre-commit hook
PRE_COMMIT_SRC="${AI_CONFIG_DIR}/tools/git/pre-commit-hook.sh"
PRE_COMMIT_DEST="${HOOKS_DIR}/pre-commit"

if [ -f "$PRE_COMMIT_SRC" ]; then
  ai_log "info" "Installing pre-commit hook"
  
  # Check if hook already exists
  if [ -f "$PRE_COMMIT_DEST" ]; then
    ai_log "info" "Existing pre-commit hook found"
    
    # Check if it's our hook or a different one
    if grep -q "AI configuration pre-commit hook" "$PRE_COMMIT_DEST"; then
      ai_log "info" "Updating existing AI pre-commit hook"
      cp "$PRE_COMMIT_SRC" "$PRE_COMMIT_DEST"
    else
      # Backup existing hook
      BACKUP_FILE="${PRE_COMMIT_DEST}.bak-$(date +%Y%m%d%H%M%S)"
      ai_log "info" "Backing up existing hook to $BACKUP_FILE"
      cp "$PRE_COMMIT_DEST" "$BACKUP_FILE"
      
      # Create new hook that calls both
      ai_log "info" "Creating composite pre-commit hook"
      cat > "$PRE_COMMIT_DEST" << EOL
#!/bin/bash
# Composite pre-commit hook
# Calls both the original hook and the AI hook

# Run original hook
if [ -x "$BACKUP_FILE" ]; then
  "$BACKUP_FILE" "\$@" || exit \$?
fi

# Run AI hook
if [ -x "$PRE_COMMIT_SRC" ]; then
  "$PRE_COMMIT_SRC" "\$@" || exit \$?
fi

exit 0
EOL
    fi
  else
    # No existing hook, just copy ours
    ai_log "info" "Installing new pre-commit hook"
    cp "$PRE_COMMIT_SRC" "$PRE_COMMIT_DEST"
  fi
  
  # Make hook executable
  chmod +x "$PRE_COMMIT_DEST"
  ai_log "success" "Pre-commit hook installed successfully"
else
  ai_log "warn" "Pre-commit hook source file not found: $PRE_COMMIT_SRC"
fi

# Install prepare-commit-msg hook
PREPARE_COMMIT_SRC="${AI_CONFIG_DIR}/tools/git/prepare-commit-msg-hook.sh"
PREPARE_COMMIT_DEST="${HOOKS_DIR}/prepare-commit-msg"

if [ -f "$PREPARE_COMMIT_SRC" ]; then
  ai_log "info" "Installing prepare-commit-msg hook"
  
  # Check if hook already exists
  if [ -f "$PREPARE_COMMIT_DEST" ]; then
    ai_log "info" "Existing prepare-commit-msg hook found"
    
    # Check if it's our hook or a different one
    if grep -q "AI-assisted commit message hook" "$PREPARE_COMMIT_DEST"; then
      ai_log "info" "Updating existing AI prepare-commit-msg hook"
      cp "$PREPARE_COMMIT_SRC" "$PREPARE_COMMIT_DEST"
    else
      # Backup existing hook
      BACKUP_FILE="${PREPARE_COMMIT_DEST}.bak-$(date +%Y%m%d%H%M%S)"
      ai_log "info" "Backing up existing hook to $BACKUP_FILE"
      cp "$PREPARE_COMMIT_DEST" "$BACKUP_FILE"
      
      # Create new hook that calls both
      ai_log "info" "Creating composite prepare-commit-msg hook"
      cat > "$PREPARE_COMMIT_DEST" << EOL
#!/bin/bash
# Composite prepare-commit-msg hook
# Calls both the original hook and the AI hook

# Get arguments
COMMIT_MSG_FILE="\$1"
COMMIT_SOURCE="\$2"
SHA1="\$3"

# Run original hook
if [ -x "$BACKUP_FILE" ]; then
  "$BACKUP_FILE" "\$@" || exit \$?
fi

# Run AI hook
if [ -x "$PREPARE_COMMIT_SRC" ]; then
  "$PREPARE_COMMIT_SRC" "\$@" || exit \$?
fi

exit 0
EOL
    fi
  else
    # No existing hook, just copy ours
    ai_log "info" "Installing new prepare-commit-msg hook"
    cp "$PREPARE_COMMIT_SRC" "$PREPARE_COMMIT_DEST"
  fi
  
  # Make hook executable
  chmod +x "$PREPARE_COMMIT_DEST"
  ai_log "success" "Prepare-commit-msg hook installed successfully"
else
  ai_log "warn" "Prepare-commit-msg hook source file not found: $PREPARE_COMMIT_SRC"
fi

ai_log "success" "Git hooks installation completed"

# Display confirmation
echo ""
echo -e "${AI_COLOR_GREEN}=== Git Hooks Installed ====${AI_COLOR_RESET}"
echo -e "Pre-commit hook: ${AI_COLOR_CYAN}$PRE_COMMIT_DEST${AI_COLOR_RESET}"
echo -e "Prepare-commit-msg hook: ${AI_COLOR_CYAN}$PREPARE_COMMIT_DEST${AI_COLOR_RESET}"
echo ""
echo -e "To disable AI commit message assistance, set:"
echo -e "  ${AI_COLOR_YELLOW}export AI_GIT_AI_ASSISTED_COMMIT=0${AI_COLOR_RESET}"
echo ""