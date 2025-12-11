#!/usr/bin/env bash
#
# verify-factory.sh - Universal Project Factory Health Check
#
# Validates that all components of the Universal Project Factory are healthy.
#
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

check_pass() {
  echo -e "${GREEN}[PASS]${NC} $1"
  PASS=$((PASS + 1))
}

check_fail() {
  echo -e "${RED}[FAIL]${NC} $1"
  FAIL=$((FAIL + 1))
}

check_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
  WARN=$((WARN + 1))
}

echo ""
echo "Universal Project Factory - Health Check"
echo "========================================="
echo ""

# 1. STACK SSOT
echo "STACK Single Source of Truth:"
if [[ -f "$DOTFILES/config/signet/src/stack/versions.ts" ]]; then
  check_pass "versions.ts exists"
else
  check_fail "versions.ts missing"
fi

if [[ -f "$DOTFILES/config/signet/versions.json" ]]; then
  check_pass "versions.json exists"
else
  check_warn "versions.json missing (optional)"
fi

echo ""

# 2. Hooks
echo "Hooks Infrastructure:"
HOOKS=(
  "unified-guard.ts"
  "unified-polish.ts"
  "enforce-versions.ts"
  "stack-enforcer.ts"
  "devops-enforcer.ts"
  "auto-migrate.ts"
  "verification-gate.ts"
)

for hook in "${HOOKS[@]}"; do
  if [[ -f "$DOTFILES/config/agents/hooks/$hook" ]]; then
    check_pass "$hook exists"
  else
    check_fail "$hook missing"
  fi
done

echo ""

# 3. Claude Code settings
echo "Claude Code Integration:"
if [[ -f "$DOTFILES/config/agents/settings/claude-code.json" ]]; then
  check_pass "claude-code.json exists"

  # Check if hooks are registered
  if grep -q "unified-guard" "$DOTFILES/config/agents/settings/claude-code.json"; then
    check_pass "unified-guard registered"
  else
    check_warn "unified-guard not registered"
  fi

  if grep -q "auto-migrate" "$DOTFILES/config/agents/settings/claude-code.json"; then
    check_pass "auto-migrate registered"
  else
    check_warn "auto-migrate not registered"
  fi
else
  check_fail "claude-code.json missing"
fi

echo ""

# 4. Runtime
echo "Runtime:"
if command -v bun &>/dev/null; then
  BUN_VERSION=$(bun --version)
  check_pass "Bun $BUN_VERSION available"
else
  check_fail "Bun not available"
fi

if command -v signet &>/dev/null || [[ -f "$DOTFILES/config/signet/src/cli.ts" ]]; then
  check_pass "Signet CLI available"
else
  check_warn "Signet CLI not in PATH"
fi

echo ""

# 5. Skills & Commands
echo "Agent Resources:"
SKILL_COUNT=$(find "$DOTFILES/config/agents/skills" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
check_pass "$SKILL_COUNT skills available"

CMD_COUNT=$(find "$DOTFILES/config/agents/commands" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
check_pass "$CMD_COUNT slash commands available"

AGENT_COUNT=$(find "$DOTFILES/config/agents/agents" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
check_pass "$AGENT_COUNT agent personas available"

echo ""

# 6. Repomix configs
echo "Context Generation:"
if [[ -f "$DOTFILES/repomix.config.json" ]]; then
  check_pass "Root repomix.config.json exists"
else
  check_warn "Root repomix.config.json missing"
fi

for concern in nix signet agents; do
  if [[ -f "$DOTFILES/config/repomix/$concern.json" ]]; then
    check_pass "config/repomix/$concern.json exists"
  else
    check_warn "config/repomix/$concern.json missing"
  fi
done

echo ""
echo "========================================="
echo -e "Results: ${GREEN}$PASS passed${NC}, ${YELLOW}$WARN warnings${NC}, ${RED}$FAIL failed${NC}"
echo ""

if [[ $FAIL -gt 0 ]]; then
  echo -e "${RED}Factory Status: UNHEALTHY${NC}"
  exit 1
else
  echo -e "${GREEN}Factory Status: HEALTHY${NC}"
  exit 0
fi
