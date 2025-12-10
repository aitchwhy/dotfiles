---
name: planning-patterns
description: Implementation planning methodology. Research before coding. Identify risks before implementation.
allowed-tools: Read, Grep, Glob, Bash
---

## Planning Philosophy

**Never start coding before understanding:**
1. What exists (codebase research)
2. What's needed (requirements)
3. What could go wrong (risks)
4. How to verify (test strategy)

## Planning Phases

### Phase 1: Requirements Analysis

```markdown
## Task: [Brief description]

### Explicit Requirements (stated)
- [ ] Requirement from user
- [ ] Requirement from spec

### Implicit Requirements (inferred)
- [ ] Error handling
- [ ] Type safety
- [ ] Performance bounds
- [ ] Security considerations

### Constraints
- Must maintain backwards compatibility
- Must work with existing auth system
- Performance: <200ms response time

### Non-Requirements (explicitly excluded)
- Not handling edge case X (will address later)
- Not supporting legacy format Y
```

### Phase 2: Codebase Research

**DO NOT WRITE CODE. Research only.**

```bash
# Find existing patterns
grep -r "pattern_name" --include="*.ts"

# Identify integration points
glob "src/**/auth*.ts"

# Read relevant modules
cat src/services/auth.ts

# Check existing tests
glob "**/*.test.ts" | xargs grep "describe.*Auth"
```

Questions to answer:
- What patterns does the codebase use?
- Where are the integration points?
- What tests exist for similar features?
- Are there similar implementations to follow?

### Phase 3: Design Document

```markdown
## Design: [Feature Name]

### Architecture Decision
[Which pattern/approach and WHY]

### Files to Modify

| File | Action | Reason |
|------|--------|--------|
| `src/services/user.ts` | modify | Add new method |
| `src/types/user.ts` | modify | Add new type |
| `src/services/user.test.ts` | create | Add tests |

### Implementation Steps

1. **Step 1: Add types** (10 lines)
   - Add `UserPreferences` type
   - Export from `types/index.ts`

2. **Step 2: Implement service** (30 lines)
   - Add `getUserPreferences` method
   - Add `setUserPreferences` method

3. **Step 3: Add tests** (50 lines)
   - Unit tests for happy path
   - Unit tests for error cases
   - Integration test for full flow

### Test Strategy

| Test Type | What | File |
|-----------|------|------|
| Unit | Service methods | `user.test.ts` |
| Unit | Type guards | `user.test.ts` |
| Integration | API endpoint | `api.test.ts` |
| E2E | User flow | `e2e/user.spec.ts` |

### Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Database migration fails | High | Low | Test on staging first |
| Cache invalidation issues | Medium | Medium | Add cache TTL |
| Breaking API change | High | Medium | Version endpoint |
```

### Phase 4: Approval Gate

**STOP AND REQUEST APPROVAL**

Present:
1. Summary of approach
2. List of files to be changed
3. Estimated scope (lines of code)
4. Known risks

Only proceed after explicit approval.

## Planning Templates

### Quick Feature (< 50 lines)

```markdown
## Quick Feature: [Name]

**Changes:**
- `file.ts`: Add function X

**Tests:**
- Add unit test for X

**Risk:** Low - isolated change
```

### Standard Feature (50-200 lines)

```markdown
## Feature: [Name]

**Requirements:** [bulleted list]

**Files:** [table of changes]

**Steps:** [numbered implementation steps]

**Tests:** [test strategy]

**Risks:** [identified risks]
```

### Major Feature (> 200 lines)

Use full template above with:
- Multiple phases
- Explicit milestones
- Review checkpoints

## Anti-Patterns

### Planning Anti-Patterns

| Anti-Pattern | Problem | Better Approach |
|--------------|---------|-----------------|
| "Just start coding" | Rework, bugs | Research first |
| "I know this codebase" | Miss new patterns | Always grep first |
| "Requirements are clear" | Hidden complexity | Document assumptions |
| "Tests later" | Untested code ships | TDD from start |
| "No risks" | Surprised by failure | Always identify risks |

### Complexity Estimation

```
Lines of Code → Complexity Level

1-20 lines    → Trivial (no plan needed)
20-50 lines   → Simple (quick plan)
50-200 lines  → Standard (full plan)
200-500 lines → Complex (phased plan)
500+ lines    → Major (multiple PRs)
```

## Research Commands

```bash
# Find similar implementations
grep -r "similar_pattern" src/

# Check for existing types
grep -r "type.*EntityName" --include="*.ts"

# Find tests for similar features
grep -r "describe.*SimilarFeature" --include="*.test.ts"

# Check imports/dependencies
grep -r "import.*from.*module" src/

# Find configuration patterns
grep -r "config\." --include="*.ts" | head -20
```
