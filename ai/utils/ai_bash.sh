#!/usr/bin/env bash
# AI Bash Configuration
# Provides command-line utilities and functions for AI-powered workflows

# ==============================================================================
# Environment Variables
# ==============================================================================

# Set default environment variables if not already set
export AI_CONFIG_DIR="${AI_CONFIG_DIR:-$HOME/.config/ai}"
export AI_PROVIDER="${AI_PROVIDER:-claude}"
export AI_MODEL="${AI_MODEL:-claude-3-7-sonnet-20250219}"
export AI_HISTORY_DIR="${AI_HISTORY_DIR:-$AI_CONFIG_DIR/history}"
export AI_PROMPT_DIR="${AI_PROMPT_DIR:-$AI_CONFIG_DIR/prompts}"
export AI_MAX_TOKENS="${AI_MAX_TOKENS:-1500}"

# Create necessary directories
mkdir -p "$AI_HISTORY_DIR"
mkdir -p "$AI_PROMPT_DIR"

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

# Get the default model for a provider
ai_get_default_model() {
  local provider="$1"
  
  case "$provider" in
    "claude") echo "claude-3-7-sonnet-20250219" ;;
    "openai") echo "gpt-4-turbo-2024-04-09" ;;
    "gemini") echo "gemini-pro" ;;
    *) echo "claude-3-7-sonnet-20250219" ;;
  esac
}

# Validate environment variables are set properly
ai_validate_env() {
  local provider="$1"
  
  case "$provider" in
    "claude")
      if [ -z "$ANTHROPIC_API_KEY" ]; then
        ai_format_output "red" "Error: ANTHROPIC_API_KEY environment variable not set"
        return 1
      fi
      ;;
    "openai")
      if [ -z "$OPENAI_API_KEY" ]; then
        ai_format_output "red" "Error: OPENAI_API_KEY environment variable not set"
        return 1
      fi
      ;;
    "gemini")
      if [ -z "$GOOGLE_API_KEY" ]; then
        ai_format_output "red" "Error: GOOGLE_API_KEY environment variable not set"
        return 1
      fi
      ;;
  esac
  
  return 0
}

# ==============================================================================
# AI Command Functions
# ==============================================================================

# Generate code using AI
ai_generate_code() {
  local language="$1"
  local prompt="$2"
  local model="${3:-$AI_MODEL}"
  local provider="${4:-$AI_PROVIDER}"
  
  ai_format_output "cyan" "Generating $language code with $provider ($model)"
  ai_format_output "yellow" "Prompt: $prompt"
  
  # Check if provider tools are available
  if ! ai_validate_env "$provider"; then
    return 1
  fi
  
  # Select appropriate prompt template
  local template_file="$AI_PROMPT_DIR/${language}-template.md"
  if [ ! -f "$template_file" ]; then
    template_file="$AI_PROMPT_DIR/code-template.md"
    if [ ! -f "$template_file" ]; then
      # Create minimal template
      mkdir -p "$AI_PROMPT_DIR"
      cat > "$template_file" << EOL
# Code Generation Template

You are an expert ${language} developer. Create well-documented, efficient, and idiomatic code based on the following request:

{{request}}

Guidelines:
- Make the code clean, readable, and maintainable
- Include appropriate error handling
- Follow modern ${language} best practices
- Add comments to explain complex logic
- If appropriate, include example usage
EOL
    fi
  fi
  
  # Replace placeholder with actual prompt
  local prompt_content
  prompt_content=$(cat "$template_file" | sed "s/{{request}}/$prompt/g")
  
  # Use appropriate CLI tool based on provider
  case "$provider" in
    "claude")
      if ai_command_exists "claude"; then
        claude --message "$prompt_content" --model "$model" --max-tokens "$AI_MAX_TOKENS"
      else
        ai_format_output "red" "Error: claude-cli not found. Please install it with 'pip install claude-cli'"
        return 1
      fi
      ;;
    "openai")
      if ai_command_exists "openai"; then
        openai api chat_completions.create -m "$model" -g user "$prompt_content" --max-tokens "$AI_MAX_TOKENS"
      else
        ai_format_output "red" "Error: openai-cli not found. Please install it with 'pip install openai'"
        return 1
      fi
      ;;
    *)
      ai_format_output "red" "Error: Unsupported provider $provider"
      return 1
      ;;
  esac
}

# Generate a commit message from git diff
ai_commit_msg() {
  local model="${1:-claude-3-haiku-20240307}"
  
  ai_format_output "cyan" "AI Commit Message Generator"
  ai_format_output "yellow" "Model: $model"
  
  # Get git diff of staged changes
  local diff
  diff=$(git diff --staged)
  
  if [ -z "$diff" ]; then
    ai_format_output "red" "No staged changes found. Stage changes with 'git add' first."
    return 1
  fi
  
  # Get git status
  local status
  status=$(git status --short)
  
  # Check if claude-cli is available
  if ! ai_command_exists "claude"; then
    ai_format_output "red" "Error: claude-cli not found. Please install it with 'pip install claude-cli'"
    return 1
  fi
  
  # Create prompt for generating commit message
  local prompt="Generate a concise, informative git commit message for the following changes. 
Follow the Conventional Commits specification (https://www.conventionalcommits.org/).
Format: <type>(<scope>): <description>

Types: feat, fix, docs, style, refactor, test, chore, perf
Scope is optional but should indicate the component being changed
Description should be present tense, lowercase, no period at end

STAGED CHANGES:
$diff

STATUS:
$status

Respond ONLY with the commit message, nothing else."
  
  # Generate commit message with Claude
  local commit_msg
  commit_msg=$(claude --message "$prompt" --model "$model" --max-tokens 100)
  
  # Display the suggested commit message
  ai_format_output "green" "Suggested commit message:"
  echo "$commit_msg"
  
  # Ask if user wants to use this message
  read -r -p "Use this commit message? [Y/n] " reply
  if [[ $reply =~ ^[Yy]$ ]] || [[ -z $reply ]]; then
    git commit -m "$commit_msg"
    ai_format_output "green" "Commit created successfully!"
  else
    ai_format_output "yellow" "Commit cancelled."
  fi
}

# Explain a code snippet or file
ai_explain_code() {
  local file_path="$1"
  local model="${2:-claude-3-haiku-20240307}"
  
  ai_format_output "cyan" "AI Code Explainer"
  ai_format_output "yellow" "Explaining: $file_path"
  ai_format_output "yellow" "Model: $model"
  
  # Validate file exists
  if [ ! -f "$file_path" ]; then
    ai_format_output "red" "Error: File $file_path does not exist"
    return 1
  fi
  
  # Read file content
  local file_content
  file_content=$(cat "$file_path")
  local file_ext="${file_path##*.}"
  
  # Check if claude-cli is available
  if ! ai_command_exists "claude"; then
    ai_format_output "red" "Error: claude-cli not found. Please install it with 'pip install claude-cli'"
    return 1
  fi
  
  # Create explanation prompt
  local explain_prompt="Explain the following code in detail:

\`\`\`$file_ext
$file_content
\`\`\`

In your explanation:
1. Summarize what the code does at a high level
2. Explain the purpose of key functions, classes, or modules
3. Walk through the logic step by step
4. Highlight any important patterns, algorithms, or techniques used
5. Note any potential issues or edge cases

Format your explanation as markdown with appropriate headings and code references."
  
  # Generate explanation with Claude
  claude --message "$explain_prompt" --model "$model" --max-tokens "$AI_MAX_TOKENS" | less -R
}

# Save AI conversation history
ai_save_history() {
  local session_id="$1"
  local output_file="${2:-$AI_HISTORY_DIR/$(date +"%Y-%m-%d")-conversation.md}"
  
  ai_format_output "cyan" "Saving AI Conversation History"
  ai_format_output "yellow" "Session ID: $session_id"
  ai_format_output "yellow" "Output file: $output_file"
  
  # Create history directory if it doesn't exist
  mkdir -p "$(dirname "$output_file")"
  
  # Call the justfile command to do the export
  if ai_command_exists "just"; then
    just claude export-conversation "$session_id"
  else
    ai_format_output "red" "Error: just command not found. Cannot export conversation."
    return 1
  fi
}

# ==============================================================================
# Bash Aliases
# ==============================================================================

# Main AI command aliases
alias ai-code='ai_generate_code'
alias ai-commit='ai_commit_msg'
alias ai-explain='ai_explain_code'
alias ai-history='ai_save_history'

# Provider shortcuts
alias claude='ai_generate_code "text" "Respond to this prompt:" "claude-3-7-sonnet-20250219" "claude"'
alias gpt4='ai_generate_code "text" "Respond to this prompt:" "gpt-4-turbo-2024-04-09" "openai"'
alias gemini='ai_generate_code "text" "Respond to this prompt:" "gemini-pro" "gemini"'

# Language-specific shortcuts
alias ai-ts='ai_generate_code "typescript"'
alias ai-py='ai_generate_code "python"'
alias ai-sh='ai_generate_code "shell"'
alias ai-go='ai_generate_code "go"'
alias ai-rs='ai_generate_code "rust"'

# ==============================================================================
# Command Wrapper for Just Integration
# ==============================================================================

# Main AI command wrapper (integrates with just)
ai() {
  local command="$1"
  shift
  
  if ai_command_exists "just"; then
    case "$command" in
      "code")
        just ai code "$@"
        ;;
      "review")
        just ai review "$@"
        ;;
      "commit")
        just ai commit-msg
        ;;
      "explain")
        just ai explain "$@"
        ;;
      "translate")
        just ai translate "$@"
        ;;
      "test")
        just ai test-gen "$@"
        ;;
      "docstrings")
        just ai docstrings "$@"
        ;;
      "history")
        just claude history "$@"
        ;;
      *)
        # Pass through to justfile
        just ai "$command" "$@"
        ;;
    esac
  else
    ai_format_output "red" "Error: just command not found. Cannot run AI commands."
    return 1
  fi
}

# API command wrapper
api() {
  local command="$1"
  shift
  
  if ai_command_exists "just"; then
    just api "$command" "$@"
  else
    ai_format_output "red" "Error: just command not found. Cannot run API commands."
    return 1
  fi
}

# ==============================================================================
# Initialization
# ==============================================================================

# Display welcome message if being sourced directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  ai_format_output "cyan" "AI Bash Configuration"
  ai_format_output "yellow" "Run 'source ${BASH_SOURCE[0]}' to load AI functions and aliases"
else
  ai_format_output "green" "AI Bash Configuration loaded successfully"
  ai_format_output "yellow" "Provider: $AI_PROVIDER"
  ai_format_output "yellow" "Model: $AI_MODEL"
  ai_format_output "yellow" "Run 'ai' to see available commands"
fi