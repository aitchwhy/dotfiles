# PARAGON Bypasses and Loop Prevention

## Bypass Mechanisms

```bash
# Skip ALL guards (emergency only)
touch .paragon-skip

# Skip specific guard
touch .paragon-skip-20  # Skip function size guard

# Refactoring session (logs but doesn't block)
touch .paragon-refactoring

# TDD bypass (temporary)
touch .tdd-skip
```

## Infinite Loop Prevention

Guards 18-26 include protection against refactoring loops:

| Mechanism | Description |
|-----------|-------------|
| Per-file cooldown | 30s between checks on same file |
| Max iterations | 3 guard-triggered edits per file |
| Guard groups | Related guards skip if sibling fired |
| Bypass files | `.paragon-skip`, `.paragon-skip-{N}` |
| Refactoring marker | `.paragon-refactoring` for sessions |

## Guard Groups

Related guards that skip if sibling fired:

- **naming**: 14, 16, 18 (names & args)
- **structure**: 20, 21, 25 (size, complexity, nesting)
- **patterns**: 19, 22, 23 (demeter, switch, null)
- **comments**: 15, 17 (comments & dead code)

## Fowler Refactoring Catalog Integration

PARAGON maps code smells to [Fowler's Refactoring Catalog](https://refactoring.com/catalog/).

| Code Smell | Refactoring |
|------------|-------------|
| Long Method | ExtractFunction |
| Long Parameter List | IntroduceParameterObject |
| Primitive Obsession | ReplacePrimitiveWithObject |
| Data Clumps | ExtractClass |
| Switch Statements | ReplaceConditionalWithPolymorphism |
| Message Chains | HideDelegate |
| Comments | ExtractFunction, RenameVariable |
| Dead Code | RemoveDeadCode |
| Duplicate Code | ExtractFunction |
| Deep Nesting | ReplaceNestedConditionalWithGuardClauses |

## Core Refactorings (Most Used)

1. **Extract Function** - Any code fragment with semantic meaning
2. **Replace Nested Conditional with Guard Clauses** - Deep nesting → early returns
3. **Introduce Parameter Object** - >3 parameters → single object
4. **Replace Conditional with Polymorphism** - switch on type → handler map
5. **Replace Loop with Pipeline** - for loops → filter/map/reduce

## Implementation Files

| File | Purpose |
|------|---------|
| `config/agents/hooks/paragon-guard.ts` | PreToolUse enforcement |
| `config/agents/rules/paragon-combined.yaml` | Combined ast-grep rules |
| `config/quality/src/stack/versions.ts` | SSOT for stack versions |
| `flake/hooks.nix` | git-hooks.nix pre-commit |
| `.github/workflows/paragon-check.yml` | CI enforcement |
