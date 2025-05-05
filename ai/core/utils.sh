#!/usr/bin/env bash
# Core bash utilities for AI operations
# Version: 1.0.0 (May 2025)

# Exit on error
set -e

# ==============================================================================
# Environment and Configuration
# ==============================================================================

# Set default environment variables if not already set
: "${AI_CONFIG_DIR:=${HOME}/.config/ai}"
: "${AI_CONFIG_FILE:=${AI_CONFIG_DIR}/core/config.yaml}"
: "${AI_HISTORY_DIR:=${AI_CONFIG_DIR}/history}"
: "${AI_PROMPTS_DIR:=${AI_CONFIG_DIR}/prompts}"
: "${AI_CACHE_DIR:=${HOME}/.cache/ai}"
: "${AI_DEFAULT_PROVIDER:=anthropic}"
: "${AI_DEFAULT_MODEL:=claude-3-7-sonnet-20250219}"
: "${AI_MAX_TOKENS:=1500}"

# Create necessary directories
mkdir -p "${AI_HISTORY_DIR}"
mkdir -p "${AI_PROMPTS_DIR}"
mkdir -p "${AI_CACHE_DIR}"

# ==============================================================================
# Helper Functions
# ==============================================================================

# Check if a command exists
ai_command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Format output with colors
ai_format_output() {
  local color="$1"
  local text="$2"
  
  case "$color" in
    "green") echo -e "\033[0;32m$text\033[0m" ;;
    "blue") echo -e "\033[0;34m$text\033[0m" ;;
    "yellow") echo -e "\033[0;33m$text\033[0m" ;;
    "red") echo -e "\033[0;31m$text\033[0m" ;;
    "purple") echo -e "\033[0;35m$text\033[0m" ;;
    "cyan") echo -e "\033[0;36m$text\033[0m" ;;
    *) echo "$text" ;;
  esac
}

# Log message with level
ai_log() {
  local level="$1"
  local message="$2"
  
  # Default to info level
  if [ -z "$level" ]; then
    level="info"
  fi
  
  # Format the log message
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  
  case "$level" in
    "debug")
      # Only show debug logs if AI_DEBUG is set
      if [ "${AI_DEBUG:-0}" -eq 1 ]; then
        ai_format_output "purple" "[DEBUG] $timestamp - $message"
      fi
      ;;
    "info")
      ai_format_output "blue" "[INFO] $timestamp - $message"
      ;;
    "warn")
      ai_format_output "yellow" "[WARN] $timestamp - $message"
      ;;
    "error")
      ai_format_output "red" "[ERROR] $timestamp - $message"
      ;;
    *)
      echo "[$level] $timestamp - $message"
      ;;
  esac
}

# Parse YAML configuration
# This is a simplified version; for production, use yq or a proper YAML parser
ai_parse_yaml() {
  local file="$1"
  local prefix="$2"
  
  # Check if file exists
  if [ ! -f "$file" ]; then
    ai_log "error" "Configuration file not found: $file"
    return 1
  fi
  
  # Check if yq or python is available for YAML parsing
  if ai_command_exists "yq"; then
    yq eval -o=props "$file"
    return 0
  fi
  
  # Fallback to simplified parsing with sed/awk
  # Note: This is very limited and doesn't handle complex YAML
  sed -e 's/:[^:\/\/]/="/g' \
      -e 's/$/"/g' \
      -e 's/ *=/=/g' \
      "$file" | 
    grep -v "^ *#" |
    grep -v "^$" |
    sed -e 's/^/export '"$prefix"'/'
}

# Load configuration settings
ai_load_config() {
  # Check if config file exists
  if [ ! -f "$AI_CONFIG_FILE" ]; then
    ai_log "error" "Configuration file not found: $AI_CONFIG_FILE"
    return 1
  }
  
  ai_log "debug" "Loading configuration from $AI_CONFIG_FILE"
  
  # Use yq if available for better YAML parsing
  if ai_command_exists "yq"; then
    # Parse specific values we need
    export AI_DEFAULT_PROVIDER=$(yq eval '.system.default_provider' "$AI_CONFIG_FILE")
    export AI_DEFAULT_MODEL=$(yq eval '.models.anthropic.claude-3-sonnet.id' "$AI_CONFIG_FILE")
    export AI_MAX_TOKENS=$(yq eval '.defaults.parameters.max_tokens' "$AI_CONFIG_FILE")
    export AI_TEMPERATURE=$(yq eval '.defaults.parameters.temperature' "$AI_CONFIG_FILE")
    export AI_TOP_P=$(yq eval '.defaults.parameters.top_p' "$AI_CONFIG_FILE")
    export AI_BASH_INTEGRATION=$(yq eval '.scripts.bash_integration' "$AI_CONFIG_FILE")
    
    # Get provider API endpoints
    export ANTHROPIC_API_ENDPOINT=$(yq eval '.providers.anthropic.api_endpoint' "$AI_CONFIG_FILE")
    export OPENAI_API_ENDPOINT=$(yq eval '.providers.openai.api_endpoint' "$AI_CONFIG_FILE")
    export GOOGLE_API_ENDPOINT=$(yq eval '.providers.google.api_endpoint' "$AI_CONFIG_FILE")
    
    # Get recommended models for tasks
    export AI_CODE_MODEL=$(yq eval '.tasks.code_generation.default' "$AI_CONFIG_FILE" | cut -d'.' -f2)
    export AI_COMMIT_MODEL=$(yq eval '.tasks.commit_messages.default' "$AI_CONFIG_FILE" | cut -d'.' -f2)
    export AI_DOC_MODEL=$(yq eval '.tasks.documentation.default' "$AI_CONFIG_FILE" | cut -d'.' -f2)
    export AI_REVIEW_MODEL=$(yq eval '.tasks.code_review.default' "$AI_CONFIG_FILE" | cut -d'.' -f2)
  else
    # Fallback to environment variables or defaults if we can't parse
    ai_log "warn" "yq not found, using default configuration values"
  fi
  
  # Validate that we have API keys for providers
  if [ -z "$ANTHROPIC_API_KEY" ] && [ "$AI_DEFAULT_PROVIDER" = "anthropic" ]; then
    ai_log "warn" "ANTHROPIC_API_KEY not set, but anthropic is the default provider"
  fi
  
  if [ -z "$OPENAI_API_KEY" ] && [ "$AI_DEFAULT_PROVIDER" = "openai" ]; then
    ai_log "warn" "OPENAI_API_KEY not set, but openai is the default provider"
  fi
  
  if [ -z "$GOOGLE_API_KEY" ] && [ "$AI_DEFAULT_PROVIDER" = "google" ]; then
    ai_log "warn" "GOOGLE_API_KEY not set, but google is the default provider"
  fi
  
  return 0
}

# Get the default model for a task
ai_get_default_model() {
  local task="$1"
  local provider="${2:-$AI_DEFAULT_PROVIDER}"
  
  case "$task" in
    "code")
      if [ -n "$AI_CODE_MODEL" ]; then
        echo "$AI_CODE_MODEL"
      else
        echo "claude-3-7-sonnet-20250219"
      fi
      ;;
    "commit")
      if [ -n "$AI_COMMIT_MODEL" ]; then
        echo "$AI_COMMIT_MODEL"
      else
        echo "claude-3-haiku-20240307"
      fi
      ;;
    "doc")
      if [ -n "$AI_DOC_MODEL" ]; then
        echo "$AI_DOC_MODEL"
      else
        echo "claude-3-7-sonnet-20250219"
      fi
      ;;
    "review")
      if [ -n "$AI_REVIEW_MODEL" ]; then
        echo "$AI_REVIEW_MODEL"
      else
        echo "claude-3-opus-20240229"
      fi
      ;;
    *)
      echo "$AI_DEFAULT_MODEL"
      ;;
  esac
}

# Validate API key for a provider
ai_validate_provider_auth() {
  local provider="$1"
  
  case "$provider" in
    "anthropic")
      if [ -z "$ANTHROPIC_API_KEY" ]; then
        ai_log "error" "ANTHROPIC_API_KEY environment variable not set"
        return 1
      fi
      ;;
    "openai")
      if [ -z "$OPENAI_API_KEY" ]; then
        ai_log "error" "OPENAI_API_KEY environment variable not set"
        return 1
      fi
      ;;
    "google")
      if [ -z "$GOOGLE_API_KEY" ]; then
        ai_log "error" "GOOGLE_API_KEY environment variable not set"
        return 1
      fi
      ;;
    "local")
      # No API key needed for local models
      return 0
      ;;
    *)
      ai_log "error" "Unknown provider: $provider"
      return 1
      ;;
  esac
  
  return 0
}

# Get language from file extension
ai_get_language() {
  local file_path="$1"
  local file_ext="${file_path##*.}"
  
  case "$file_ext" in
    js|jsx) echo "javascript" ;;
    ts|tsx) echo "typescript" ;;
    py) echo "python" ;;
    rb) echo "ruby" ;;
    go) echo "go" ;;
    rs) echo "rust" ;;
    java) echo "java" ;;
    c|cpp|cc|h|hpp) echo "c" ;;
    cs) echo "csharp" ;;
    sh|bash|zsh) echo "bash" ;;
    md) echo "markdown" ;;
    yml|yaml) echo "yaml" ;;
    json) echo "json" ;;
    html|htm) echo "html" ;;
    css|scss|sass) echo "css" ;;
    sql) echo "sql" ;;
    nix) echo "nix" ;;
    php) echo "php" ;;
    swift) echo "swift" ;;
    kt|kts) echo "kotlin" ;;
    *) echo "text" ;;
  esac
}

# Execute 'just' command with given parameters
ai_execute_just() {
  local namespace="$1"
  local command="$2"
  shift 2
  
  # Join remaining arguments with spaces
  local args="$*"
  
  if ! ai_command_exists "just"; then
    ai_log "error" "just command not found. Please install it."
    return 1
  fi
  
  ai_log "debug" "Executing: just $namespace:$command $args"
  just "$namespace:$command" $args
}

# Extract code blocks from markdown
ai_extract_code() {
  local markdown="$1"
  local language="${2:-}"
  
  # Use awk to extract code blocks
  if [ -n "$language" ]; then
    # Extract blocks with specific language
    echo "$markdown" | awk -v lang="$language" '
      /^```'"$language"'/ {
        in_block = 1;
        next;
      }
      /^```/ {
        in_block = 0;
        next;
      }
      in_block {
        print;
      }
    '
  else
    # Extract all code blocks
    echo "$markdown" | awk '
      /^```[a-zA-Z0-9_-]*/ {
        in_block = 1;
        next;
      }
      /^```/ {
        in_block = 0;
        next;
      }
      in_block {
        print;
      }
    '
  fi
}

# ==============================================================================
# Initialization
# ==============================================================================

# Load configuration
ai_load_config

# Display welcome message if running directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  ai_format_output "cyan" "AI Bash Utilities (Core)"
  ai_format_output "yellow" "Run 'source ${BASH_SOURCE[0]}' to load AI functions and utilities"
else
  ai_log "debug" "AI Bash Utilities (Core) loaded successfully"
fi