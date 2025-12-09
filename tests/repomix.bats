#!/usr/bin/env bats
# RepoMix configuration tests
# Run with: bats tests/repomix.bats
# Or: just test-rx
#
# Tests verify repomix.config.json is valid and rx CLI works.

# ============================================================================
# Helper Functions
# ============================================================================

DOTFILES="${HOME}/dotfiles"

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# Tier 1: Config Validation
# ============================================================================

@test "config: repomix.config.json exists" {
  [ -f "$DOTFILES/repomix.config.json" ]
}

@test "config: repomix.config.json is valid JSON" {
  jq . "$DOTFILES/repomix.config.json" > /dev/null
}

@test "config: instructionFilePath is defined" {
  instruction_file=$(jq -r '.output.instructionFilePath // empty' "$DOTFILES/repomix.config.json")
  [ -n "$instruction_file" ]
}

@test "config: instructionFilePath points to existing file" {
  instruction_file=$(jq -r '.output.instructionFilePath // empty' "$DOTFILES/repomix.config.json")
  [ -f "$DOTFILES/$instruction_file" ]
}

@test "config: include patterns are defined" {
  count=$(jq '.include | length' "$DOTFILES/repomix.config.json")
  [ "$count" -gt 0 ]
}

@test "config: output style is xml" {
  style=$(jq -r '.output.style // empty' "$DOTFILES/repomix.config.json")
  [ "$style" = "xml" ]
}

# ============================================================================
# Tier 2: CLI Availability
# ============================================================================

@test "cli: rx command exists" {
  command_exists rx
}

@test "cli: repomix command exists" {
  command_exists repomix
}

@test "cli: rx help works" {
  run rx help
  [ "$status" -eq 0 ]
}

# ============================================================================
# Tier 3: Functional Tests
# ============================================================================

@test "cli: rx pack succeeds in dotfiles" {
  cd "$DOTFILES"
  run rx pack
  [ "$status" -eq 0 ]
}

@test "cli: repomix-output.xml is generated" {
  cd "$DOTFILES"
  # Run pack if output doesn't exist
  [ -f "repomix-output.xml" ] || rx pack
  [ -f "repomix-output.xml" ]
}

@test "cli: repomix-output.xml is valid XML" {
  cd "$DOTFILES"
  [ -f "repomix-output.xml" ] || rx pack
  # Check XML starts with proper declaration or root element
  head -1 "$DOTFILES/repomix-output.xml" | grep -qE '^(<\?xml|<)'
}
