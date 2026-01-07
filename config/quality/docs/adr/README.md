---
format: madr
version: 3.0.0
---

# Architecture Decision Records

MADR-format decisions for the Claude Code quality system.

## Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [001](001-fiber-parallelism.md) | Effect Fiber Parallelism | accepted | 2026-01-07 |
| [002](002-all-errors-collection.md) | Collect All Errors | accepted | 2026-01-07 |
| [003](003-precompiled-regexes.md) | Pre-compiled Regexes | accepted | 2026-01-07 |
| [004](004-typescript-ssot.md) | TypeScript SSOT | accepted | 2025-12-28 |
| [005](005-stack-enforcement.md) | Stack Enforcement | accepted | 2025-12-28 |
| [006](006-ast-grep-rules.md) | AST-grep Rules | accepted | 2025-12-28 |
| [007](007-hook-architecture.md) | Hook Architecture | accepted | 2025-12-28 |
| [008](008-nix-managed-config.md) | Nix-Managed Config | accepted | 2025-12-01 |

## Categories

### Performance
- [ADR-001](001-fiber-parallelism.md) - Fiber parallelism
- [ADR-003](003-precompiled-regexes.md) - Pre-compiled regexes

### User Experience
- [ADR-002](002-all-errors-collection.md) - All errors collection

### Architecture
- [ADR-004](004-typescript-ssot.md) - TypeScript SSOT
- [ADR-007](007-hook-architecture.md) - Hook architecture
- [ADR-008](008-nix-managed-config.md) - Nix management

### Enforcement
- [ADR-005](005-stack-enforcement.md) - Stack versions
- [ADR-006](006-ast-grep-rules.md) - AST-grep rules

## Format

All ADRs use [MADR 3.0.0](https://adr.github.io/madr/) format with YAML frontmatter:

```yaml
---
status: proposed | accepted | deprecated | superseded
date: YYYY-MM-DD
decision-makers: []
---
```

See [template.md](template.md) for full structure.
