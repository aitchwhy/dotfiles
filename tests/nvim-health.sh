#!/usr/bin/env bash
# NeoVim startup health check - verifies no Lua errors on startup
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              NeoVim Startup Health Check                       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

FAILED=0

# Test 1: Basic startup (no errors)
echo -n "Testing basic NeoVim startup... "
STARTUP_OUTPUT=$(nvim --headless -c "qa" 2>&1) || true
if echo "$STARTUP_OUTPUT" | grep -qi "error\|module.*not found"; then
  echo -e "${RED}FAILED${NC}"
  echo "Startup errors detected:"
  echo "$STARTUP_OUTPUT"
  FAILED=1
else
  echo -e "${GREEN}OK${NC}"
fi

# Test 2: lazy.nvim loads
echo -n "Testing lazy.nvim plugin manager... "
LAZY_CHECK=$(nvim --headless -c "lua print(require('lazy') and 'OK')" -c "qa" 2>&1 | grep -o "OK" | tail -1) || true
if [[ "$LAZY_CHECK" != "OK" ]]; then
  echo -e "${RED}FAILED${NC}"
  FAILED=1
else
  echo -e "${GREEN}OK${NC}"
fi

# Test 3: Copilot module loads
echo -n "Testing copilot.lua module... "
COPILOT_CHECK=$(nvim --headless -c "lua local ok = pcall(require, 'copilot'); print(ok and 'OK' or 'MISSING')" -c "qa" 2>&1 | grep -oE "(OK|MISSING)" | tail -1) || true
if [[ "$COPILOT_CHECK" == "MISSING" ]]; then
  echo -e "${YELLOW}NOT INSTALLED${NC} (run :Lazy sync)"
  # Don't fail - copilot might not be synced yet
elif [[ "$COPILOT_CHECK" == "OK" ]]; then
  echo -e "${GREEN}OK${NC}"
else
  echo -e "${RED}FAILED${NC}"
  FAILED=1
fi

# Test 4: Blink.cmp loads
echo -n "Testing blink.cmp completion... "
BLINK_CHECK=$(nvim --headless -c "lua print(require('blink.cmp') and 'OK')" -c "qa" 2>&1 | grep -o "OK" | tail -1) || true
if [[ "$BLINK_CHECK" != "OK" ]]; then
  echo -e "${RED}FAILED${NC}"
  FAILED=1
else
  echo -e "${GREEN}OK${NC}"
fi

# Test 5: LSP config available
echo -n "Testing LSP configuration... "
LSP_CHECK=$(nvim --headless -c "lua print(require('lspconfig') and 'OK')" -c "qa" 2>&1 | grep -o "OK" | tail -1) || true
if [[ "$LSP_CHECK" != "OK" ]]; then
  echo -e "${RED}FAILED${NC}"
  FAILED=1
else
  echo -e "${GREEN}OK${NC}"
fi

# Test 6: No module not found errors in messages
echo -n "Testing for missing module errors... "
MSG_CHECK=$(nvim --headless -c "lua vim.cmd('messages')" -c "qa" 2>&1) || true
if echo "$MSG_CHECK" | grep -qi "module.*not found"; then
  echo -e "${RED}FAILED${NC}"
  echo "Module errors in messages:"
  echo "$MSG_CHECK" | grep -i "module.*not found"
  FAILED=1
else
  echo -e "${GREEN}OK${NC}"
fi

echo ""
if [[ $FAILED -eq 0 ]]; then
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}                    ALL TESTS PASSED                            ${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  exit 0
else
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${RED}                    SOME TESTS FAILED                           ${NC}"
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  exit 1
fi
