---
description: Autonomous verification loop until green
allowed-tools: Bash, Edit, Read
---

# Verification Loop

Run verification -> fix errors -> repeat until green.

## Detection
```bash
# Detect package manager
if [ -f "pnpm-lock.yaml" ]; then PM="pnpm"
elif [ -f "bun.lockb" ]; then PM="bun"
elif [ -f "package-lock.json" ]; then PM="npm"
fi
```

## Verification Order
```bash
$PM typecheck    # TypeScript
$PM lint         # oxlint + ast-grep
$PM test --run   # vitest
$PM build        # turbo/tsc
```

## Stop Conditions
1. **All 4 checks pass** -> Success, invoke @code-reviewer
2. **Same error 3+ times** -> Stop, report blocker with full context
3. **10+ iterations** -> Stop, report status

## Post-Success
After all checks pass:
1. Run `@code-reviewer` on changed files
2. Output summary of fixes applied
