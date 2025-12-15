#!/usr/bin/env bats
# AI CLI smoke tests for Claude Code configuration
# Run with: bats tests/ai-cli.bats
# Or: just test-ai
#
# Tests verify that Claude CLI is properly configured with skills and knowledge.
# Tier 3 tests (knowledge verification) query your local Claude subscription.

# ============================================================================
# Helper Functions
# ============================================================================

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Run claude in print mode with no tools (just knowledge check)
ask_claude() {
  claude -p "$1" --tools "" 2>/dev/null
}

# Check if output contains expected text (case insensitive)
contains() {
  echo "$1" | grep -qi "$2"
}

# ============================================================================
# Tier 1: Static Config Validation
# ============================================================================

@test "config: ~/.claude directory exists" {
  [ -d "$HOME/.claude" ]
}

@test "config: ~/.claude/settings.json exists" {
  [ -f "$HOME/.claude/settings.json" ]
}

@test "config: ~/.claude/CLAUDE.md exists" {
  [ -f "$HOME/.claude/CLAUDE.md" ]
}

@test "config: ~/.claude/skills directory exists" {
  [ -d "$HOME/.claude/skills" ]
}

@test "config: ~/.claude/commands directory exists" {
  [ -d "$HOME/.claude/commands" ]
}

@test "config: skills directory has skills" {
  count=$(/bin/ls -1d "$HOME/.claude/skills"/*/ 2>/dev/null | wc -l | tr -d ' ')
  [ "$count" -ge 10 ]
}

@test "config: commands directory has commands" {
  count=$(/bin/ls "$HOME/.claude/commands"/*.md 2>/dev/null | wc -l | tr -d ' ')
  [ "$count" -ge 4 ]
}

@test "config: source claude-code.json is valid JSON" {
  jq . "$HOME/dotfiles/config/agents/settings/claude-code.json" > /dev/null
}

@test "config: source gemini.json is valid JSON" {
  jq . "$HOME/dotfiles/config/agents/settings/gemini.json" > /dev/null
}

@test "config: source settings.json is valid JSON" {
  jq . "$HOME/dotfiles/config/agents/settings.json" > /dev/null
}

@test "config: typescript-patterns skill exists" {
  [ -d "$HOME/.claude/skills/typescript-patterns" ] || [ -L "$HOME/.claude/skills/typescript-patterns" ]
}

@test "config: zod-patterns skill exists" {
  [ -d "$HOME/.claude/skills/zod-patterns" ] || [ -L "$HOME/.claude/skills/zod-patterns" ]
}

@test "config: result-patterns skill exists" {
  [ -d "$HOME/.claude/skills/result-patterns" ] || [ -L "$HOME/.claude/skills/result-patterns" ]
}

@test "config: tdd-patterns skill exists" {
  [ -d "$HOME/.claude/skills/tdd-patterns" ] || [ -L "$HOME/.claude/skills/tdd-patterns" ]
}

@test "config: verification-first skill exists" {
  [ -d "$HOME/.claude/skills/verification-first" ] || [ -L "$HOME/.claude/skills/verification-first" ]
}

@test "config: each skill has SKILL.md" {
  for skill in "$HOME/.claude/skills"/*/; do
    skill_name=$(basename "$skill")
    [ -f "$skill/SKILL.md" ] || fail "Missing SKILL.md in $skill_name"
  done
}

# ============================================================================
# Tier 2: CLI Availability
# ============================================================================

@test "cli: claude command exists" {
  command_exists claude
}

@test "cli: claude --version works" {
  run claude --version
  [ "$status" -eq 0 ]
}

@test "cli: claude --help works" {
  run claude --help
  [ "$status" -eq 0 ]
}

# ============================================================================
# Tier 3: Knowledge Verification (queries Claude)
# These tests use your Claude subscription to verify context is loaded.
# Skip with: bats tests/ai-cli.bats --filter-tags '!live'
# ============================================================================

# ----------------------------------------------------------------------------
# Skill Knowledge Tests - Verify each skill's content is loaded
# ----------------------------------------------------------------------------

# bats test_tags=live
@test "skill: typescript-patterns - knows branded types" {
  skip_if_no_api
  result=$(ask_claude "What is a branded type in TypeScript? Show the type definition with __brand symbol.")
  contains "$result" "__brand" || contains "$result" "Brand" || fail "Missing branded type knowledge: $result"
}

# bats test_tags=live
@test "skill: result-patterns - knows Result type" {
  skip_if_no_api
  result=$(ask_claude "What is the Result type pattern for error handling? Show the TypeScript type with ok discriminant.")
  contains "$result" "ok" || fail "Missing Result type knowledge: $result"
}

# bats test_tags=live
@test "skill: zod-patterns - knows schema-first" {
  skip_if_no_api
  result=$(ask_claude "In schema-first development with Zod, what is derived from the schema? One word answer.")
  contains "$result" "type" || contains "$result" "Type" || fail "Missing Zod schema knowledge: $result"
}

# bats test_tags=live
@test "skill: verification-first - knows banned phrases" {
  skip_if_no_api
  result=$(ask_claude "What phrase is banned that starts with 'should' when claiming code works?")
  contains "$result" "should" || fail "Missing verification-first knowledge: $result"
}

# bats test_tags=live
@test "skill: tdd-patterns - knows Red-Green-Refactor" {
  skip_if_no_api
  result=$(ask_claude "What are the three phases of TDD? Answer in three words separated by dashes.")
  contains "$result" "Red" || contains "$result" "red" || fail "Missing TDD knowledge: $result"
}

# bats test_tags=live
@test "skill: ember-patterns - knows test credentials" {
  skip_if_no_api
  result=$(ask_claude "What phone number is used for test credentials in the Ember project? Just the number.")
  contains "$result" "5550000000" || fail "Expected 5550000000, got: $result"
}

# bats test_tags=live
@test "skill: nix-darwin-patterns - knows flake structure" {
  skip_if_no_api
  result=$(ask_claude "What input is needed for nix-darwin in a flake? Just name it.")
  contains "$result" "darwin" || contains "$result" "nix-darwin" || fail "Missing nix-darwin knowledge: $result"
}

# Helper to skip live tests if API not available
skip_if_no_api() {
  # Check if we can reach Claude (basic connectivity test)
  if ! command_exists claude; then
    skip "Claude CLI not installed"
  fi
  # Check if ANTHROPIC_API_KEY or Claude auth exists
  if [ ! -f "$HOME/.claude/credentials.json" ] && [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    skip "No Claude credentials found"
  fi
}
