---
description: Code review checklist
allowed-tools: Read, Grep, Glob, Bash
---

# Code Review: $ARGUMENTS

Review the specified files/changes against this checklist:

## Type Safety

- [ ] No `any` types
- [ ] Proper null/undefined handling
- [ ] Branded types for IDs where appropriate
- [ ] Result types for operations that can fail

## Naming

- [ ] Semantic variable names (`userId` not `id`)
- [ ] Descriptive function names (verb + noun)
- [ ] No abbreviations except well-known ones

## Error Handling

- [ ] All errors caught and handled
- [ ] Meaningful error messages
- [ ] No swallowed exceptions

## Security

- [ ] No secrets in code
- [ ] Input validation at boundaries
- [ ] Proper authentication/authorization

## Performance

- [ ] No N+1 queries
- [ ] Appropriate caching
- [ ] No unnecessary re-renders (React)

## Testing

- [ ] Tests for new functionality
- [ ] Edge cases covered
- [ ] Tests are deterministic

## Documentation

- [ ] Complex logic explained
- [ ] Public API documented
- [ ] README updated if needed

## Output Format

**Critical** (must fix):
- Issue description

**Suggestions** (consider):
- Improvement idea

**Approved**:
- What looks good
