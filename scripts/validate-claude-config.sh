#!/usr/bin/env bash
# validate-claude-config.sh
# Comprehensive validation of Claude Code configuration
# Catches symlink mismatches, missing references, and config errors
# Uses modern CLI tools: rg (ripgrep), fd, eza
#
# Usage: ./scripts/validate-claude-config.sh
# Exit codes: 0=pass, 1=fail
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
AGENTS_DIR="$DOTFILES/config/agents"
AGENTS_NIX="$AGENTS_DIR/nix/agents.nix"
CLAUDE_NIX="$DOTFILES/modules/home/apps/claude.nix"
SETTINGS_JSON="$AGENTS_DIR/settings/claude-code.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

error() {
  echo -e "${RED}ERROR: $1${NC}" >&2
  ((ERRORS++))
}

warn() {
  echo -e "${YELLOW}WARNING: $1${NC}" >&2
  ((WARNINGS++))
}

pass() {
  echo -e "${GREEN}✓${NC} $1"
}

section() {
  echo ""
  echo "═══════════════════════════════════════════════════════════════"
  echo "$1"
  echo "═══════════════════════════════════════════════════════════════"
}

# ═══════════════════════════════════════════════════════════════════════════
# Test 1: Skills Cross-Reference
# ═══════════════════════════════════════════════════════════════════════════
section "Test 1: Skills Cross-Reference"

# Get skills defined in directory (using eza instead of ls)
SKILLS_DIR=$(eza --oneline "$AGENTS_DIR/skills/" | sort)
SKILLS_DIR_COUNT=$(echo "$SKILLS_DIR" | wc -l | tr -d ' ')

# Get skills symlinked in agents.nix (using rg instead of grep)
# Extract patterns like: ".claude/skills/XXX".source =
SKILLS_NIX=$(rg '\.claude/skills/' "$AGENTS_NIX" | \
  sed -E 's/.*\.claude\/skills\/([a-z0-9-]+)".*/\1/' | sort | uniq)
SKILLS_NIX_COUNT=$(echo "$SKILLS_NIX" | wc -l | tr -d ' ')

echo "Skills in directory: $SKILLS_DIR_COUNT"
echo "Skills symlinked in agents.nix: $SKILLS_NIX_COUNT"

# Find skills in directory but NOT symlinked
MISSING_SYMLINKS=$(comm -23 <(echo "$SKILLS_DIR") <(echo "$SKILLS_NIX"))
if [ -n "$MISSING_SYMLINKS" ]; then
  error "Skills in directory but NOT symlinked in agents.nix:"
  echo "$MISSING_SYMLINKS" | while read skill; do
    echo "  - $skill"
  done
else
  pass "All skills in directory are symlinked"
fi

# Find skills symlinked but NOT in directory (broken symlinks)
ORPHAN_SYMLINKS=$(comm -13 <(echo "$SKILLS_DIR") <(echo "$SKILLS_NIX"))
if [ -n "$ORPHAN_SYMLINKS" ]; then
  error "Skills symlinked but directory DOES NOT EXIST (broken symlinks):"
  echo "$ORPHAN_SYMLINKS" | while read skill; do
    echo "  - $skill"
  done
else
  pass "No orphan symlinks"
fi

# Exact count match
if [ "$SKILLS_DIR_COUNT" -eq "$SKILLS_NIX_COUNT" ]; then
  pass "Skill counts match: $SKILLS_DIR_COUNT"
else
  error "Skill count mismatch: directory=$SKILLS_DIR_COUNT, symlinked=$SKILLS_NIX_COUNT"
fi

# ═══════════════════════════════════════════════════════════════════════════
# Test 2: MCP Servers Validation
# ═══════════════════════════════════════════════════════════════════════════
section "Test 2: MCP Servers Validation"

# Extract MCP server names from claude.nix
# Look for patterns like: servername = { in mcpServerDefs block
MCP_SERVERS=$(awk '/mcpServerDefs = \{/,/^  \};/' "$CLAUDE_NIX" | \
  sed -n '/^    [a-z].*= {$/p' | sed -E 's/^    ([a-z0-9-]+) =.*/\1/' | sort)
MCP_COUNT=$(echo "$MCP_SERVERS" | wc -l | tr -d ' ')

echo "MCP servers defined in claude.nix: $MCP_COUNT"
echo "$MCP_SERVERS" | while read server; do
  echo "  - $server"
done

# Validate expected servers exist (using rg instead of grep)
REQUIRED_SERVERS="memory filesystem context7 fetch repomix signet"
for server in $REQUIRED_SERVERS; do
  if echo "$MCP_SERVERS" | rg -q "^${server}$"; then
    pass "Required server present: $server"
  else
    error "Required server MISSING: $server"
  fi
done

# ═══════════════════════════════════════════════════════════════════════════
# Test 3: Settings JSON Validation
# ═══════════════════════════════════════════════════════════════════════════
section "Test 3: Settings JSON Validation"

if [ -f "$SETTINGS_JSON" ]; then
  # JSON syntax check
  if jq empty "$SETTINGS_JSON" 2>/dev/null; then
    pass "settings/claude-code.json is valid JSON"
  else
    error "settings/claude-code.json has invalid JSON syntax"
  fi

  # Check required fields
  if jq -e '.hooks' "$SETTINGS_JSON" >/dev/null 2>&1; then
    pass "hooks field present"
  else
    error "hooks field missing"
  fi

  if jq -e '.permissions' "$SETTINGS_JSON" >/dev/null 2>&1; then
    pass "permissions field present"
  else
    error "permissions field missing"
  fi

  # Check hook types defined (using rg instead of grep)
  HOOK_TYPES=$(jq -r '.hooks | keys[]' "$SETTINGS_JSON" 2>/dev/null || echo "")
  for hook_type in PreToolUse PostToolUse SessionStart Stop; do
    if echo "$HOOK_TYPES" | rg -q "^${hook_type}$"; then
      pass "Hook type defined: $hook_type"
    else
      warn "Hook type not defined: $hook_type"
    fi
  done
else
  error "Settings file not found: $SETTINGS_JSON"
fi

# ═══════════════════════════════════════════════════════════════════════════
# Test 4: Hook Files Exist
# ═══════════════════════════════════════════════════════════════════════════
section "Test 4: Hook Files Validation"

HOOKS_DIR="$AGENTS_DIR/hooks"

# Extract hook files referenced in settings (using rg instead of grep)
REFERENCED_HOOKS=$(jq -r '.. | .command? // empty' "$SETTINGS_JSON" 2>/dev/null | \
  rg -o 'hooks/[a-zA-Z0-9_-]+\.(ts|sh)' | sed -E 's/hooks\/([a-zA-Z0-9_-]+\.(ts|sh))/\1/' | sort | uniq)

if [ -n "$REFERENCED_HOOKS" ]; then
  echo "$REFERENCED_HOOKS" | while read hook; do
    if [ -f "$HOOKS_DIR/$hook" ]; then
      pass "Hook exists: $hook"
    else
      error "Hook MISSING: $hook"
    fi
  done
else
  warn "No hooks referenced in settings"
fi

# ═══════════════════════════════════════════════════════════════════════════
# Test 5: Agent Definitions
# ═══════════════════════════════════════════════════════════════════════════
section "Test 5: Agent Definitions"

AGENTS_MD_DIR="$AGENTS_DIR/agents"
# Using fd instead of ls
AGENT_COUNT=$(fd -e md . "$AGENTS_MD_DIR" 2>/dev/null | wc -l | tr -d ' ')
echo "Agent definitions found: $AGENT_COUNT"

for agent in "$AGENTS_MD_DIR"/*.md; do
  if [ -f "$agent" ]; then
    name=$(basename "$agent")
    # Check for required frontmatter (using rg instead of grep)
    if rg -q "^name:" "$agent"; then
      pass "$name has 'name:' field"
    else
      error "$name missing 'name:' field"
    fi
    if rg -q "^description:" "$agent"; then
      pass "$name has 'description:' field"
    else
      error "$name missing 'description:' field"
    fi
  fi
done

# ═══════════════════════════════════════════════════════════════════════════
# Test 6: Commands Validation
# ═══════════════════════════════════════════════════════════════════════════
section "Test 6: Commands Validation"

COMMANDS_DIR="$AGENTS_DIR/commands"
# Using fd instead of ls
COMMAND_COUNT=$(fd -e md . "$COMMANDS_DIR" 2>/dev/null | wc -l | tr -d ' ')
echo "Commands found: $COMMAND_COUNT"

for cmd in "$COMMANDS_DIR"/*.md; do
  if [ -f "$cmd" ]; then
    name=$(basename "$cmd")
    # Check file is not empty
    if [ -s "$cmd" ]; then
      pass "$name is not empty"
    else
      error "$name is empty"
    fi
  fi
done

# ═══════════════════════════════════════════════════════════════════════════
# Test 7: AGENT.md Cross-References
# ═══════════════════════════════════════════════════════════════════════════
section "Test 7: AGENT.md Cross-References"

AGENT_MD="$AGENTS_DIR/AGENT.md"

if [ -f "$AGENT_MD" ]; then
  # Extract skill references from AGENT.md (using rg instead of grep)
  # Match pattern: | `skill-name` | (single backticked name with hyphen)
  AGENT_MD_SKILLS=$(rg -o '\| `[a-z]+-[a-z0-9-]+` \|' "$AGENT_MD" | \
    sed -E 's/.*`([a-z]+-[a-z0-9-]+)`.*/\1/' | sort | uniq || true)

  if [ -n "$AGENT_MD_SKILLS" ]; then
    # Check each referenced skill exists (use process substitution to avoid subshell)
    while read -r skill; do
      if [ -d "$AGENTS_DIR/skills/$skill" ]; then
        pass "AGENT.md reference exists: $skill"
      else
        warn "AGENT.md references non-existent skill: $skill"
      fi
    done <<< "$AGENT_MD_SKILLS"
  fi
  pass "AGENT.md exists"
else
  error "AGENT.md not found"
fi

# ═══════════════════════════════════════════════════════════════════════════
# Test 8: Nix Evaluation Test
# ═══════════════════════════════════════════════════════════════════════════
section "Test 8: Nix Configuration Evaluation"

if command -v nix &>/dev/null; then
  cd "$DOTFILES"
  if nix flake check --no-build 2>/dev/null; then
    pass "Nix flake evaluation succeeded"
  else
    error "Nix flake evaluation failed"
  fi
else
  warn "Nix not available, skipping flake evaluation"
fi

# ═══════════════════════════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════════════════════════
section "Summary"

echo ""
echo "Skills:   $SKILLS_DIR_COUNT defined, $SKILLS_NIX_COUNT symlinked"
echo "MCP:      $MCP_COUNT servers"
echo "Agents:   $AGENT_COUNT definitions"
echo "Commands: $COMMAND_COUNT commands"
echo ""

if [ $ERRORS -gt 0 ]; then
  echo -e "${RED}FAILED: $ERRORS error(s), $WARNINGS warning(s)${NC}"
  exit 1
elif [ $WARNINGS -gt 0 ]; then
  echo -e "${YELLOW}PASSED with $WARNINGS warning(s)${NC}"
  exit 0
else
  echo -e "${GREEN}PASSED: All tests passed${NC}"
  exit 0
fi
