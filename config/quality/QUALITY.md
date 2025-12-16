# Code Quality SSOT

This directory is the **Single Source of Truth** for code quality across all projects.

## Files

| File | Purpose | Consumption |
|------|---------|-------------|
| `biome.json` | Linting + formatting config | Copy or extend |
| `lefthook.base.yml` | Git hook orchestration | Copy to `lefthook.yml` |
| `commitlint.config.js` | Commit message validation | Symlink |
| `ci-quality.yml` | GitHub Actions template | Copy to `.github/workflows/` |
| `sync-versions.ts` | Version drift detection | Run via `bun run` |
| `src/stack/versions.ts` | Package version SSOT | Import in code |

## Quick Start

```bash
# In your project root:

# 1. Copy biome config
cp ~/dotfiles/config/quality/biome.json biome.json

# 2. Copy lefthook config
cp ~/dotfiles/config/quality/lefthook.base.yml lefthook.yml

# 3. Symlink commitlint
ln -sf ~/dotfiles/config/quality/commitlint.config.js commitlint.config.js

# 4. Copy CI workflow
cp ~/dotfiles/config/quality/ci-quality.yml .github/workflows/quality.yml

# 5. Check version drift
bun run ~/dotfiles/config/quality/sync-versions.ts . --dry-run

# 6. Sync versions (applies changes)
bun run ~/dotfiles/config/quality/sync-versions.ts .
```

## Enforcement Layers

Code quality is enforced at four layers:

```
┌─────────────────────────────────────────────────────┐
│                    1. EDITOR                         │
│   EditorConfig + Biome LSP (real-time feedback)     │
├─────────────────────────────────────────────────────┤
│                  2. PRE-COMMIT                       │
│   Lefthook → Biome + ast-grep + typecheck           │
├─────────────────────────────────────────────────────┤
│                      3. CI                           │
│   GitHub Actions → same checks + PARAGON guards     │
├─────────────────────────────────────────────────────┤
│                4. CLAUDE CODE                        │
│   paragon-guard.ts PreToolUse hooks (39 guards)     │
└─────────────────────────────────────────────────────┘
```

## PARAGON Guards

The ast-grep rules in `config/agents/rules/ast-grep/` implement core PARAGON guards:

| Rule | Guard | Description |
|------|-------|-------------|
| `no-any-type.yml` | Guard 5 | Block `: any`, `as any` |
| `no-z-infer.yml` | Guard 6 | Block `z.infer<>` (TS is SSOT) |
| `no-console.yml` | Guard 26 | Block `console.*` in prod |
| `no-throw.yml` | Guard 14 | Warn on bare `throw` |
| `no-mocks.yml` | Guard 7 | Block jest/vi mocks |
| `forbidden-imports.yml` | Guard 4/31 | Block banned packages |

Full guard documentation: `config/agents/skills/paragon/SKILL.md`

## Version Management

### STACK.ts

All package versions are defined in `src/stack/versions.ts`:

```typescript
import { STACK, getNpmVersion, getDrift } from '@dotfiles/quality/src/stack/versions';

// Get specific version
const reactVersion = getNpmVersion('react'); // '19.2.1'

// Check drift
const drift = getDrift(myPackageJson.dependencies);
```

### Detecting Drift

```bash
# Dry run - shows what would change
bun run ~/dotfiles/config/quality/sync-versions.ts /path/to/project --dry-run

# Apply changes
bun run ~/dotfiles/config/quality/sync-versions.ts /path/to/project
```

## Biome Configuration

Key settings in `biome.json`:

- **Formatter**: 2 spaces, single quotes, semicolons
- **Line width**: 100 characters
- **noExplicitAny**: error (use proper types)
- **noConsole**: error (use structured logging)
- **noUnusedImports**: error (clean imports)

### Overrides

Console logging is allowed in:
- `**/e2e/**` - E2E tests
- `**/scripts/**` - Build scripts
- `**/*.test.ts`, `**/*.spec.ts` - Unit tests
- `**/logger.ts` - Logger implementations

## Related Resources

- `config/agents/hooks/paragon-guard.ts` - Claude Code enforcement
- `config/agents/hooks/unified-polish.ts` - Auto-formatting
- `config/agents/skills/paragon/SKILL.md` - PARAGON documentation
- `docs/stack.md` - Stack documentation
