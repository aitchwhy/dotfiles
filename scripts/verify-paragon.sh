#!/usr/bin/env bash
# PARAGON Compliance Verification Script v2.1
# Run: just verify-paragon
# Verifies 25 guards for Clean Code, SOLID, and evidence-based development
# Uses modern CLI tools: rg (ripgrep), fd

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

echo "=============================================="
echo "  PARAGON Compliance Verification v2.1"
echo "=============================================="
echo ""

# Guard 3: Forbidden Files (using fd instead of find)
echo -n "Guard 3 (Forbidden Files): "
forbidden_found=0
for pattern in package-lock.json yarn.lock pnpm-lock.yaml .eslintrc .prettierrc jest.config Dockerfile docker-compose.yml docker-compose.yaml .dockerignore; do
  if fd --hidden --exclude .git --exclude node_modules "$pattern" 2>/dev/null | rg -q .; then
    forbidden_found=1
    break
  fi
done
if [[ $forbidden_found -eq 1 ]]; then
  echo -e "${RED}FAIL${NC}"
  ERRORS=$((ERRORS + 1))
else
  echo -e "${GREEN}PASS${NC}"
fi

# Guard 5: No Any Types (using rg instead of grep)
echo -n "Guard 5 (No Any Types): "
if rg ':\s*any\b|as\s+any\b|<any\s*>' -t ts \
  --glob '!*.d.ts' --glob '!*.test.ts' --glob '!*.spec.ts' \
  --glob '!*-guard.ts' --glob '!sig-*.ts' --glob '!node_modules/**' 2>/dev/null | \
  rg -v ':\s*(\*|//)' | rg -v "'\s*:\s*any\s*'" | rg -q .; then
  echo -e "${RED}FAIL${NC}"
  ERRORS=$((ERRORS + 1))
else
  echo -e "${GREEN}PASS${NC}"
fi

# Guard 6: No z.infer (using rg instead of grep)
echo -n "Guard 6 (No z.infer): "
if rg 'z\.infer\s*<|z\.input\s*<|z\.output\s*<' -t ts \
  --glob '!*-guard.ts' --glob '!sig-*.ts' --glob '!ast-engine.ts' \
  --glob '!node_modules/**' 2>/dev/null | rg -q .; then
  echo -e "${RED}FAIL${NC}"
  ERRORS=$((ERRORS + 1))
else
  echo -e "${GREEN}PASS${NC}"
fi

# Guard 7: No Mocks (using rg instead of grep)
echo -n "Guard 7 (No Mocks): "
if rg 'jest\.mock\s*\(|vi\.mock\s*\(|Mock[A-Z][a-zA-Z]*Live' -t ts -t js \
  --glob '!*-guard.ts' --glob '!sig-*.ts' --glob '!node_modules/**' 2>/dev/null | rg -q .; then
  echo -e "${RED}FAIL${NC}"
  ERRORS=$((ERRORS + 1))
else
  echo -e "${GREEN}PASS${NC}"
fi

# Guard 13: No Assumption Language (using rg instead of grep)
echo -n "Guard 13 (No Assumptions): "
if rg -i 'should (now )?work|should fix|this fixes|probably (works|fixed)|I think (this|it)|might (work|fix)|likely (fixed|works)' -t ts \
  --glob '!*.test.ts' --glob '!*.spec.ts' --glob '!node_modules/**' 2>/dev/null | rg -q .; then
  echo -e "${YELLOW}WARN${NC}"
  WARNINGS=$((WARNINGS + 1))
else
  echo -e "${GREEN}PASS${NC}"
fi

# Guard 18: Function Arguments (>3 params) - using rg instead of grep
echo -n "Guard 18 (Function Args): "
if rg 'function\s+\w+\s*\([^)]*,[^)]*,[^)]*,[^)]*,' -t ts \
  --glob '!*.test.ts' --glob '!*.spec.ts' --glob '!*.d.ts' \
  --glob '!node_modules/**' 2>/dev/null | rg -q .; then
  echo -e "${YELLOW}WARN${NC}"
  WARNINGS=$((WARNINGS + 1))
else
  echo -e "${GREEN}PASS${NC}"
fi

# Guard 19: Law of Demeter (method chain violations) - using rg instead of grep
echo -n "Guard 19 (Law of Demeter): "
if rg '\.\w+\([^)]*\)\.\w+\([^)]*\)\.\w+\(' -t ts \
  --glob '!*.test.ts' --glob '!*.spec.ts' --glob '!*.d.ts' \
  --glob '!node_modules/**' 2>/dev/null | \
  rg -v '(pipe|then|catch|Effect|Layer|Stream|filter|map|flatMap)' | rg -q .; then
  echo -e "${YELLOW}WARN${NC}"
  WARNINGS=$((WARNINGS + 1))
else
  echo -e "${GREEN}PASS${NC}"
fi

# Guard 23: Null Returns - using rg instead of grep
echo -n "Guard 23 (No Null Returns): "
if rg 'return\s+null\s*;' -t ts \
  --glob '!*.test.ts' --glob '!*.spec.ts' --glob '!*.d.ts' \
  --glob '!node_modules/**' 2>/dev/null | rg -q .; then
  echo -e "${YELLOW}WARN${NC}"
  WARNINGS=$((WARNINGS + 1))
else
  echo -e "${GREEN}PASS${NC}"
fi

# PARAGON Skill Exists
echo -n "PARAGON Skill Exists: "
if [[ -f "config/agents/skills/paragon/SKILL.md" ]]; then
  echo -e "${GREEN}PASS${NC}"
else
  echo -e "${RED}FAIL${NC}"
  ERRORS=$((ERRORS + 1))
fi

# PARAGON Guard Exists
echo -n "PARAGON Guard Exists: "
if [[ -f "config/agents/hooks/paragon-guard.ts" ]]; then
  echo -e "${GREEN}PASS${NC}"
else
  echo -e "${RED}FAIL${NC}"
  ERRORS=$((ERRORS + 1))
fi

# Check for bypass files (advisory)
echo -n "Bypass Files Check: "
if [[ -f ".paragon-skip" ]] || [[ -f ".paragon-refactoring" ]]; then
  echo -e "${YELLOW}WARN (bypass active)${NC}"
  WARNINGS=$((WARNINGS + 1))
else
  echo -e "${GREEN}PASS${NC}"
fi

echo ""
echo "=============================================="
if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
  echo -e "  ${GREEN}PARAGON COMPLIANT${NC}"
elif [[ $ERRORS -eq 0 ]]; then
  echo -e "  ${YELLOW}PARAGON COMPLIANT (${WARNINGS} warning(s))${NC}"
else
  echo -e "  ${RED}${ERRORS} violation(s), ${WARNINGS} warning(s)${NC}"
fi
echo "=============================================="

exit $ERRORS
