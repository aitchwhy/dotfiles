---
description: Quick code review
---

# Quick Code Review

Review recent changes focusing on:

1. **Type Safety**: Any `any` types? Missing type guards?
2. **Error Handling**: All error paths covered? Result types used?
3. **Security**: Secrets exposed? Injection vectors?
4. **Performance**: N+1 queries? Unnecessary re-renders?

## Steps

1. Run `git diff HEAD~1` to see recent changes
2. Analyze each file for the 4 focus areas
3. Output findings in the format below

## Output Format

```
REVIEW: [file/feature name]
━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Types: [PASS/CONCERN]
✓ Errors: [PASS/CONCERN]
✓ Security: [PASS/CONCERN]
✓ Performance: [PASS/CONCERN]

Issues Found:
1. ...

Suggested Fixes:
1. ...
```

If all areas pass, respond with a brief "All clear" summary.
