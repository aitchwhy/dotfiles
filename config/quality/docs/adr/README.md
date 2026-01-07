---
format: madr
version: 4.0.0
---

# Architecture Decision Records

MADR 4.0 format decisions for the Claude Code quality system.

## Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [001](001-fiber-parallelism.md) | Effect Fiber Parallelism for Guards | accepted | 2026-01-07 |
| [002](002-all-errors-collection.md) | Collect All Errors, Not Fail-Fast | accepted | 2026-01-07 |
| [003](003-precompiled-regexes.md) | Pre-compile Regexes at Module Scope | accepted | 2026-01-07 |
| [004](004-typescript-ssot.md) | TypeScript SSOT for Configuration | accepted | 2025-12-28 |
| [005](005-stack-enforcement.md) | Enforce Stack via Forbidden Packages | accepted | 2025-12-28 |
| [006](006-ast-grep-rules.md) | AST-grep YAML for Pattern Enforcement | accepted | 2025-12-28 |
| [007](007-hook-architecture.md) | Pre-Tool-Use Hook Architecture | accepted | 2025-12-28 |
| [008](008-nix-managed-config.md) | Nix-Managed Claude Configuration | accepted | 2025-12-01 |

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

All ADRs use [MADR 4.0.0](https://adr.github.io/madr/) format.

Key sections:
- **Context and Problem Statement** - What situation prompted this decision?
- **Decision Drivers** - Forces and concerns motivating the choice
- **Considered Options** - Alternatives evaluated
- **Decision Outcome** - Chosen option with justification
- **Consequences** - Good and bad impacts
- **Confirmation** - How to verify implementation matches decision

See [template.md](template.md) for full structure.
