---
status: accepted
date: 2025-12-28
decision-makers: [hank]
consulted: []
informed: []
---

# Enforce Stack Versions and Forbidden Packages

## Context and Problem Statement

The project uses a specific technology stack (Effect-TS, Expo SDK, etc.). How should we prevent drift and enforce consistency?

## Decision Drivers

* Prevent accidental installation of deprecated packages
* Maintain version alignment across projects
* Provide clear alternatives when blocking packages

## Considered Options

* Manual code review
* ESLint/oxlint rules
* Pre-tool-use hook with forbidden list
* package.json overrides

## Decision Outcome

Chosen option: "Pre-tool-use hook with forbidden list", because it blocks violations before they reach disk.

### Consequences

* Good, because violations blocked at write-time
* Good, because clear error with reason and alternative
* Good, because centralized in `src/stack/forbidden.ts`
* Bad, because requires hook to be running

## Validation

```typescript
// Forbidden package structure
{
  name: 'moment',
  reason: 'Legacy datetime library',
  alternative: 'date-fns or Effect Duration',
}

// Hook must check package.json writes
if (filePath?.endsWith('package.json')) {
  // Parse and check dependencies
}
```

## More Information

* Stack versions: `src/stack/versions.ts`
* Forbidden list: `src/stack/forbidden.ts`
* Related: [ADR-004](004-typescript-ssot.md)
