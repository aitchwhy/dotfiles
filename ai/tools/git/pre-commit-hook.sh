#!/usr/bin/env bash
# AI configuration pre-commit hook
# Version: 1.0.0 (May 2025)
#
# This pre-commit hook validates AI configuration files and prompts,
# ensuring they follow best practices and conventions.

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

ai_log "info" "Running AI configuration pre-commit hook"

# Get changed files
CHANGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

# Exit if no files changed
if [ -z "$CHANGED_FILES" ]; then
  ai_log "info" "No files to validate"
  exit 0
fi

# Check only AI-related files
AI_RELATED_FILES=$(echo "$CHANGED_FILES" | grep -E "^config/ai/|^\.config/ai/")

if [ -z "$AI_RELATED_FILES" ]; then
  ai_log "info" "No AI configuration files changed"
  exit 0
fi

# ==============================================================================
# Validation functions
# ==============================================================================

# Validate YAML files
validate_yaml() {
  local file="$1"
  
  # Skip if file doesn't exist or isn't a YAML file
  if [ ! -f "$file" ] || [[ ! "$file" =~ \.(yaml|yml)$ ]]; then
    return 0
  }
  
  ai_log "info" "Validating YAML: $file"
  
  # Check if yq is available
  if ai_command_exists "yq"; then
    # Validate with yq
    if ! yq eval --exit-status "$file" > /dev/null; then
      ai_log "error" "Invalid YAML in $file"
      return 1
    fi
  elif ai_command_exists "python"; then
    # Fallback to Python
    if ! python -c "import yaml; yaml.safe_load(open('$file'))"; then
      ai_log "error" "Invalid YAML in $file"
      return 1
    fi
  else
    ai_log "warn" "No YAML validator found (install yq or python-yaml)"
    return 0
  fi
  
  return 0
}

# Validate JSON files
validate_json() {
  local file="$1"
  
  # Skip if file doesn't exist or isn't a JSON file
  if [ ! -f "$file" ] || [[ ! "$file" =~ \.json$ ]]; then
    return 0
  }
  
  ai_log "info" "Validating JSON: $file"
  
  # Validate with jq if available
  if ai_command_exists "jq"; then
    if ! jq empty "$file"; then
      ai_log "error" "Invalid JSON in $file"
      return 1
    fi
  elif ai_command_exists "python"; then
    # Fallback to Python
    if ! python -c "import json; json.load(open('$file'))"; then
      ai_log "error" "Invalid JSON in $file"
      return 1
    fi
  else
    ai_log "warn" "No JSON validator found (install jq or python)"
    return 0
  fi
  
  return 0
}

# Validate TypeScript files
validate_typescript() {
  local file="$1"
  
  # Skip if file doesn't exist or isn't a TypeScript file
  if [ ! -f "$file" ] || [[ ! "$file" =~ \.(ts|tsx)$ ]]; then
    return 0
  }
  
  ai_log "info" "Validating TypeScript: $file"
  
  # Use tsc if available
  if ai_command_exists "tsc"; then
    if ! tsc --noEmit "$file"; then
      ai_log "error" "TypeScript validation failed for $file"
      return 1
    fi
  else
    ai_log "warn" "No TypeScript validator found (install typescript)"
    return 0
  fi
  
  return 0
}

# Validate shell scripts
validate_shell() {
  local file="$1"
  
  # Skip if file doesn't exist or isn't a shell script
  if [ ! -f "$file" ] || [[ ! "$file" =~ \.(sh|bash|zsh)$ ]]; then
    if [[ "$file" =~ /utils/ ]] && head -n 1 "$file" | grep -q "#!/.*sh"; then
      # Check if it's a shell script by shebang
      :
    else
      return 0
    fi
  fi
  
  ai_log "info" "Validating shell script: $file"
  
  # Use shellcheck if available
  if ai_command_exists "shellcheck"; then
    if ! shellcheck "$file"; then
      ai_log "error" "ShellCheck validation failed for $file"
      return 1
    fi
  else
    ai_log "warn" "ShellCheck not found, skipping shell validation"
    return 0
  fi
  
  return 0
}

# Validate prompt templates
validate_prompt() {
  local file="$1"
  
  # Skip if file doesn't exist or isn't in prompts directory
  if [ ! -f "$file" ] || [[ ! "$file" =~ /prompts/ ]]; then
    return 0
  }
  
  ai_log "info" "Validating prompt template: $file"
  
  # Check for common issues in prompt templates
  local issues=0
  
  # Check for empty file
  if [ ! -s "$file" ]; then
    ai_log "error" "Empty prompt template: $file"
    ((issues++))
  fi
  
  # Check for missing sections (simplified check)
  if [[ "$file" =~ \.(md|markdown)$ ]]; then
    local has_header=0
    local has_instructions=0
    
    # Check if there's at least one heading
    if grep -q "^#" "$file"; then
      has_header=1
    fi
    
    # Check for instructions-like content
    if grep -q -i "instructions\|guidelines\|follow\|ensure\|create\|generate" "$file"; then
      has_instructions=1
    fi
    
    if [ "$has_header" -eq 0 ]; then
      ai_log "warn" "Prompt template lacks headings: $file"
    fi
    
    if [ "$has_instructions" -eq 0 ]; then
      ai_log "warn" "Prompt template may lack clear instructions: $file"
    fi
  fi
  
  return "$issues"
}

# Validate core configuration
validate_config() {
  local file="$1"
  
  # Only validate the main config.yaml
  if [ "$file" != "${AI_CONFIG_DIR}/core/config.yaml" ] && [ "$file" != "config/ai/core/config.yaml" ]; then
    return 0
  }
  
  ai_log "info" "Validating core configuration: $file"
  
  # Validate YAML first
  validate_yaml "$file" || return 1
  
  # Additional schema-specific validation
  local required_fields=("system" "models" "providers" "tasks" "defaults")
  
  for field in "${required_fields[@]}"; do
    if ! grep -q "$field:" "$file"; then
      ai_log "error" "Missing required field '$field' in $file"
      return 1
    fi
  done
  
  return 0
}

# ==============================================================================
# Main validation loop
# ==============================================================================

VALIDATION_FAILED=0

for file in $AI_RELATED_FILES; do
  # Determine file type and validate accordingly
  if [[ "$file" =~ \.(yaml|yml)$ ]]; then
    validate_yaml "$file" || VALIDATION_FAILED=1
    validate_config "$file" || VALIDATION_FAILED=1
  elif [[ "$file" =~ \.json$ ]]; then
    validate_json "$file" || VALIDATION_FAILED=1
  elif [[ "$file" =~ \.(ts|tsx)$ ]]; then
    validate_typescript "$file" || VALIDATION_FAILED=1
  elif [[ "$file" =~ \.(sh|bash|zsh)$ ]] || [[ "$file" =~ /utils/ ]] && head -n 1 "$file" 2>/dev/null | grep -q "#!/.*sh"; then
    validate_shell "$file" || VALIDATION_FAILED=1
  elif [[ "$file" =~ /prompts/ ]]; then
    validate_prompt "$file" || VALIDATION_FAILED=1
  fi
done

# Exit with appropriate status
if [ $VALIDATION_FAILED -eq 1 ]; then
  ai_log "error" "AI configuration validation failed"
  exit 1
else
  ai_log "info" "AI configuration validation successful"
  exit 0
fi