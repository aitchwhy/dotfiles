#!/usr/bin/env bash
# PARAGON Compliance Verification Script v2.0
# Run: just verify-paragon
# Verifies 25 guards for Clean Code, SOLID, and evidence-based development

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

echo "=============================================="
echo "  PARAGON Compliance Verification v2.0"
echo "=============================================="
echo ""

# Guard 3: Forbidden Files (exclude all node_modules and .git)
echo -n "Guard 3 (Forbidden Files): "
forbidden_found=0
for pattern in package-lock.json yarn.lock pnpm-lock.yaml .eslintrc .prettierrc jest.config Dockerfile docker-compose.yml docker-compose.yaml .dockerignore; do
  if find . -name "*$pattern*" -not -path "*/.git/*" -not -path "*/node_modules/*" 2>/dev/null | grep -q .; then
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

# Guard 5: No Any Types (exclude tests, comments, guard/tool files)
echo -n "Guard 5 (No Any Types): "
if grep -rE ':\s*any\b|as\s+any\b|<any\s*>' --include="*.ts" --include="*.tsx" --exclude-dir=node_modules --exclude="*.d.ts" --exclude="*.test.ts" --exclude="*.spec.ts" --exclude="*-guard.ts" --exclude="sig-*.ts" . 2>/dev/null | grep -vE ':\s*(\*|//)' | grep -vE "'\s*:\s*any\s*'" | grep -q .; then
  echo -e "${RED}FAIL${NC}"
  ERRORS=$((ERRORS + 1))
else
  echo -e "${GREEN}PASS${NC}"
fi

# Guard 6: No z.infer (exclude guard/tool files that document these patterns)
echo -n "Guard 6 (No z.infer): "
if grep -rE 'z\.infer\s*<|z\.input\s*<|z\.output\s*<' --include="*.ts" --include="*.tsx" --exclude-dir=node_modules --exclude="*-guard.ts" --exclude="sig-*.ts" --exclude="ast-engine.ts" . 2>/dev/null | grep -q .; then
  echo -e "${RED}FAIL${NC}"
  ERRORS=$((ERRORS + 1))
else
  echo -e "${GREEN}PASS${NC}"
fi

# Guard 7: No Mocks (exclude guard/tool files that document these patterns)
echo -n "Guard 7 (No Mocks): "
if grep -rE 'jest\.mock\s*\(|vi\.mock\s*\(|Mock[A-Z][a-zA-Z]*Live' --include="*.ts" --include="*.tsx" --include="*.js" --exclude-dir=node_modules --exclude="*-guard.ts" --exclude="sig-*.ts" . 2>/dev/null | grep -q .; then
  echo -e "${RED}FAIL${NC}"
  ERRORS=$((ERRORS + 1))
else
  echo -e "${GREEN}PASS${NC}"
fi

# Guard 13: No Assumption Language
echo -n "Guard 13 (No Assumptions): "
if grep -rEi 'should (now )?work|should fix|this fixes|probably (works|fixed)|I think (this|it)|might (work|fix)|likely (fixed|works)' --include="*.ts" --include="*.tsx" --exclude="*.test.ts" --exclude="*.spec.ts" --exclude-dir=node_modules . 2>/dev/null | grep -q .; then
  echo -e "${YELLOW}WARN${NC}"
  WARNINGS=$((WARNINGS + 1))
else
  echo -e "${GREEN}PASS${NC}"
fi

# Guard 18: Function Arguments (>3 params) - Check for obvious violations
echo -n "Guard 18 (Function Args): "
if grep -rE 'function\s+\w+\s*\([^)]*,[^)]*,[^)]*,[^)]*,' --include="*.ts" --include="*.tsx" --exclude="*.test.ts" --exclude="*.spec.ts" --exclude="*.d.ts" --exclude-dir=node_modules . 2>/dev/null | grep -q .; then
  echo -e "${YELLOW}WARN${NC}"
  WARNINGS=$((WARNINGS + 1))
else
  echo -e "${GREEN}PASS${NC}"
fi

# Guard 19: Law of Demeter (method chain violations)
echo -n "Guard 19 (Law of Demeter): "
if grep -rE '\.\w+\([^)]*\)\.\w+\([^)]*\)\.\w+\(' --include="*.ts" --include="*.tsx" --exclude="*.test.ts" --exclude="*.spec.ts" --exclude="*.d.ts" --exclude-dir=node_modules . 2>/dev/null | grep -vE '(pipe|then|catch|Effect|Layer|Stream|filter|map|flatMap)' | grep -q .; then
  echo -e "${YELLOW}WARN${NC}"
  WARNINGS=$((WARNINGS + 1))
else
  echo -e "${GREEN}PASS${NC}"
fi

# Guard 23: Null Returns
echo -n "Guard 23 (No Null Returns): "
if grep -rE 'return\s+null\s*;' --include="*.ts" --include="*.tsx" --exclude="*.test.ts" --exclude="*.spec.ts" --exclude="*.d.ts" --exclude-dir=node_modules . 2>/dev/null | grep -q .; then
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
