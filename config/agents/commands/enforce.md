Run STACK enforcement checks on the current project.

## Usage

```bash
# Full 5-tier verification
signet verify

# Pattern-only (fast)
signet verify --tiers patterns

# With auto-fix
signet verify --fix
```

## What Gets Checked

| Tier | Component | What It Checks |
|------|-----------|----------------|
| 1 | Patterns | TypeScript-first Zod, no throw, no mocks, no any |
| 2 | Formal | Contracts, invariants, property tests |
| 3 | Execution | tsc --noEmit, biome check, bun test |
| 4 | Review | Multi-agent review (critic, synthesizer) |
| 5 | Context | Hexagonal architecture, circular deps |

## Quick Commands

```bash
# Full enforcement
signet verify

# Doctor check (health)
signet doctor

# Migrate project to STACK
signet migrate --dry-run
signet migrate
```

## STACK Authority

Source of truth: `config/quality/src/stack/versions.ts`

Import pattern:
```typescript
import { STACK, getNpmVersion } from '@/stack';
```
