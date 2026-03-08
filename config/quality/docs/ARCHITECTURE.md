# Quality System Architecture

Claude Code quality enforcement through hooks and configuration generation.

## System Overview

```
config/quality/
├── src/
│   ├── hooks/           # Pre/post tool enforcement
│   ├── stack/           # Version SSOT, forbidden packages
│   ├── generators/      # settings.json generator
│   ├── schemas/         # Configuration schemas
│   ├── lib/             # Shared utilities
│   └── generate.ts      # Generator entry point
├── generated/           # Output (DO NOT EDIT)
│   └── claude/          # Claude Code artifacts
└── docs/                # This documentation
    └── adr/             # Architecture decisions
```

## Core Subsystems

### 1. Hook System

Pre-tool-use hooks enforce quality before writes reach disk.

| Component | Purpose |
|-----------|---------|
| `pre-tool-use.ts` | Entry point, orchestrates guards |
| `effect-hook.ts` | Types, fiber utilities |
| `guards/procedural.ts` | Procedural guards |

**Execution Model:** All guards run as parallel Effect fibers with `concurrency: 'unbounded'`. See [ADR-001](adr/001-fiber-parallelism.md).

### 2. Stack Enforcement

Centralized version management and package blocking.

| File | Purpose |
|------|---------|
| `stack/versions.ts` | Version SSOT for all dependencies |
| `stack/forbidden.ts` | Blocked packages with alternatives |

See [ADR-005](adr/005-stack-enforcement.md).

## Guard Categories

| Category | Count | Source | Blocks |
|----------|-------|--------|--------|
| Procedural | 17 | `guards/procedural.ts` | Bash, commits, DevOps |
| Package | 1 | `stack/forbidden.ts` | Forbidden npm packages |
| Command | 1 | Inline | Dangerous shell commands |

## Data Flow

```
Tool Use (Write/Edit/Bash)
         │
         ▼
   pre-tool-use.ts
         │
         ├── runGuardsFibers() ─── Effect.all({ concurrency: 'unbounded' })
         │   │
         │   ├── Procedural guards (17)
         │   ├── Package check (1)
         │   └── Command check (1)
         │
         ▼
   Aggregate Results
         │
         ├── All pass → approve
         └── Any fail → block (show ALL violations)
```

## Key Decisions

| Decision | ADR | Summary |
|----------|-----|---------|
| Fiber parallelism | [001](adr/001-fiber-parallelism.md) | Effect.all with unbounded concurrency |
| All errors | [002](adr/002-all-errors-collection.md) | Collect all violations, not fail-fast |
| Pre-compiled regex | [003](adr/003-precompiled-regexes.md) | Module-scope patterns |
| TypeScript SSOT | [004](adr/004-typescript-ssot.md) | Generate from TS source |
| Stack enforcement | [005](adr/005-stack-enforcement.md) | Forbidden packages |
| Hook architecture | [007](adr/007-hook-architecture.md) | Pre-tool-use blocking |
| Nix management | [008](adr/008-nix-managed-config.md) | home-manager integration |
| Network/API toolkit | [009](adr/009-network-api-toolkit.md) | 6 CLI tools, minimal coverage |

## Commands

```bash
cd config/quality
bun run generate   # Regenerate settings.json
bun run typecheck  # Validate types
bun run test       # Run tests
```

## Related

- Root: `/Users/hank/dotfiles/CLAUDE.md`
- Claude SSOT: `modules/home/apps/claude.nix`
- Nix rebuild: `just switch`
