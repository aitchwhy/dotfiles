#!/usr/bin/env bash
# Shared helper functions for scripts

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Logging functions
log() { echo -e "${BLUE}==>${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*" >&2; }
header() { echo -e "\n${BOLD}$*${NC}"; }

# System detection
is_macos() { [[ "$(uname)" == "Darwin" ]]; }
is_arm64() { [[ "$(uname -m)" == "arm64" ]]; }
is_apple_silicon() { is_macos && is_arm64; }

# Command checking
has_command() { command -v "$1" >/dev/null 2>&1; }
require_command() {
  local cmd="$1"
  if ! has_command "$cmd"; then
    error "Required command not found: $cmd"
    return 1
  fi
}

# Path handling
ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    success "Created directory: $dir"
  fi
}

# Backup handling
backup_file() {
  local file="$1"
  if [[ -e "$file" ]]; then
    local backup="$file.backup-$(date +%Y%m%d-%H%M%S)"
    mv "$file" "$backup"
    success "Backed up: $file → $backup"
  fi
}
