---
description: Run full validation pipeline (typecheck, lint, test)
allowed-tools: Bash, Read
---

Run the complete validation pipeline for this project:

## 1. Type Check

```bash
bun run typecheck || tsc --noEmit
```

## 2. Lint

```bash
bun run lint || bunx biome check .
```

## 3. Unit Tests

```bash
bun test
```

## 4. E2E Tests (if Playwright configured)

```bash
bunx playwright test 2>/dev/null || echo "No E2E tests configured"
```

## Report Results

| Step | Status | Duration |
|------|--------|----------|
| Typecheck | ✅/❌ | Xs |
| Lint | ✅/❌ | Xs |
| Unit Tests | ✅/❌ | Xs |
| E2E Tests | ✅/❌/⏭️ | Xs |

If any step fails, stop and report the specific errors.
