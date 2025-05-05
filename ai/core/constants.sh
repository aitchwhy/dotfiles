#!/usr/bin/env bash
# Constants for AI bash utilities
# Version: 1.0.0 (May 2025)

# ===== Environment Variables =====

# Directory paths
: "${AI_CONFIG_DIR:=${HOME}/.config/ai}"
: "${AI_CORE_DIR:=${AI_CONFIG_DIR}/core}"
: "${AI_PROMPTS_DIR:=${AI_CONFIG_DIR}/prompts}"
: "${AI_HISTORY_DIR:=${AI_CONFIG_DIR}/history}"
: "${AI_CACHE_DIR:=${HOME}/.cache/ai}"
: "${AI_TEMPLATES_DIR:=${AI_CONFIG_DIR}/templates}"
: "${AI_TOOLS_DIR:=${AI_CONFIG_DIR}/tools}"

# Configuration paths
: "${AI_CONFIG_FILE:=${AI_CORE_DIR}/config.yaml}"
: "${AI_LOG_FILE:=${AI_CACHE_DIR}/ai.log}"

# Default settings
: "${AI_DEFAULT_PROVIDER:=anthropic}"
: "${AI_DEFAULT_MODEL:=claude-3-7-sonnet-20250219}"
: "${AI_MAX_TOKENS:=1500}"
: "${AI_TEMPERATURE:=0.3}"
: "${AI_TOP_P:=0.95}"
: "${AI_TIMEOUT:=60000}"
: "${AI_DEBUG:=0}"

# ===== Provider API Models =====

# Anthropic/Claude models
export AI_MODEL_CLAUDE_OPUS="claude-3-opus-20240229"
export AI_MODEL_CLAUDE_SONNET="claude-3-7-sonnet-20250219"
export AI_MODEL_CLAUDE_HAIKU="claude-3-haiku-20240307"

# OpenAI models
export AI_MODEL_GPT4_TURBO="gpt-4-turbo-2024-04-09"
export AI_MODEL_GPT4="gpt-4-0125-preview"
export AI_MODEL_GPT35="gpt-3.5-turbo-0125"

# Google models
export AI_MODEL_GEMINI_PRO="gemini-pro"
export AI_MODEL_GEMINI_ULTRA="gemini-1.5-pro"

# Local models
export AI_MODEL_MIXTRAL="mixtral-8x7b-32768"
export AI_MODEL_LLAMA3="llama-3-70b-instruct"

# ===== Provider API Endpoints =====

# API endpoints
export AI_ENDPOINT_ANTHROPIC="https://api.anthropic.com/v1/messages"
export AI_ENDPOINT_OPENAI="https://api.openai.com/v1/chat/completions"
export AI_ENDPOINT_GOOGLE="https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
export AI_ENDPOINT_LOCAL="http://localhost:11434/api/generate"

# ===== Provider API Headers =====

# API headers
export AI_HEADER_ANTHROPIC="anthropic-version: 2023-06-01"
export AI_HEADER_CONTENT_TYPE="content-type: application/json"

# ===== Task-specific model mappings =====

# Default models for each task
export AI_TASK_CODE_GEN="anthropic.claude-3-7-sonnet-20250219"
export AI_TASK_CODE_REVIEW="anthropic.claude-3-opus-20240229"
export AI_TASK_DOCUMENTATION="anthropic.claude-3-7-sonnet-20250219"
export AI_TASK_COMMIT_MESSAGES="anthropic.claude-3-haiku-20240307"
export AI_TASK_API_DESIGN="anthropic.claude-3-opus-20240229"
export AI_TASK_QUICK_ASSIST="anthropic.claude-3-haiku-20240307"
export AI_TASK_COMPLEX_REASONING="anthropic.claude-3-opus-20240229"

# ===== Language file extensions =====

# Mapping of file extensions to languages
declare -A AI_LANG_EXTENSIONS
AI_LANG_EXTENSIONS=(
  ["js"]="javascript"
  ["jsx"]="javascript"
  ["ts"]="typescript"
  ["tsx"]="typescript"
  ["py"]="python"
  ["rb"]="ruby"
  ["go"]="go"
  ["rs"]="rust"
  ["java"]="java"
  ["c"]="c"
  ["cpp"]="c++"
  ["h"]="c"
  ["hpp"]="c++"
  ["cs"]="csharp"
  ["sh"]="bash"
  ["bash"]="bash"
  ["zsh"]="bash"
  ["md"]="markdown"
  ["yaml"]="yaml"
  ["yml"]="yaml"
  ["json"]="json"
  ["html"]="html"
  ["css"]="css"
  ["scss"]="css"
  ["sql"]="sql"
  ["nix"]="nix"
  ["php"]="php"
  ["swift"]="swift"
  ["kt"]="kotlin"
)

# ===== Console colors =====

# ANSI color codes
export AI_COLOR_RED="\033[0;31m"
export AI_COLOR_GREEN="\033[0;32m"
export AI_COLOR_YELLOW="\033[0;33m"
export AI_COLOR_BLUE="\033[0;34m"
export AI_COLOR_PURPLE="\033[0;35m"
export AI_COLOR_CYAN="\033[0;36m"
export AI_COLOR_WHITE="\033[0;37m"
export AI_COLOR_RESET="\033[0m"

export AI_COLOR_BOLD="\033[1m"
export AI_COLOR_UNDERLINE="\033[4m"

# ===== Message templates =====

# Common message formats
export AI_MSG_ERROR="${AI_COLOR_RED}[ERROR]${AI_COLOR_RESET}"
export AI_MSG_WARNING="${AI_COLOR_YELLOW}[WARNING]${AI_COLOR_RESET}"
export AI_MSG_INFO="${AI_COLOR_BLUE}[INFO]${AI_COLOR_RESET}"
export AI_MSG_SUCCESS="${AI_COLOR_GREEN}[SUCCESS]${AI_COLOR_RESET}"
export AI_MSG_DEBUG="${AI_COLOR_PURPLE}[DEBUG]${AI_COLOR_RESET}"

# ===== Feature flags =====

# Enable/disable features (0=disabled, 1=enabled)
export AI_FEATURE_STREAMING=1
export AI_FEATURE_CACHE=1
export AI_FEATURE_TEMPLATES=1
export AI_FEATURE_HISTORY=1
export AI_FEATURE_LOCAL_FALLBACK=1
export AI_FEATURE_FUNCTION_CALLING=1

# ===== Integration configurations =====

# Git integration
export AI_GIT_COMMIT_MSG_HOOK=".git/hooks/prepare-commit-msg"
export AI_GIT_PRE_COMMIT_HOOK=".git/hooks/pre-commit"
export AI_GIT_CONVENTIONAL_COMMITS=1
export AI_GIT_AI_ASSISTED_COMMIT=1

# IDE integration
export AI_IDE_VSCODE_EXT="anthropic.claude-vscode"
export AI_IDE_CURSOR_CONFIG=".cursor/settings.json"

# API tools
export AI_API_VALIDATOR="spectral"
export AI_API_MOCK_SERVER="prism"
export AI_API_GENERATOR="openapi-generator-cli"