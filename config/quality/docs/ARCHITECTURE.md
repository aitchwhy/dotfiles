# Quality System Architecture

Claude Code quality enforcement through hooks, skills, and configuration generation.

## System Overview

```
config/quality/
├── src/
│   ├── skills/          # 34 context skills (Effect, Expo, etc.)
│   ├── personas/        # 14 subagent personas
│   ├── memories/        # 34 engineering patterns
│   ├── hooks/           # Pre/post tool enforcement
│   ├── stack/           # Version SSOT, forbidden packages
│   ├── rules/           # Rule definitions
│   └── generate.ts      # Multi-adapter generator
├── rules/paragon/       # 21 AST-grep YAML rules
├── generated/           # Output (DO NOT EDIT)
│   ├── claude/          # Claude Code artifacts
│   ├── cursor/          # Cursor rules
│   └── gemini/          # Gemini config
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
| `guards/procedural.ts` | 17 procedural guards |
| `ast-grep.ts` | AST pattern matching |

**Execution Model:** All guards run as parallel Effect fibers with `concurrency: 'unbounded'`. See [ADR-001](adr/001-fiber-parallelism.md).

### 2. Skills System

Skills provide contextual knowledge loaded based on file globs.

```typescript
// src/skills/effect-ts.ts
export const effectTs: Skill = {
  name: 'effect-ts',
  globs: ['**/*.ts'],
  content: `Effect-TS patterns...`,
}
```

**Generation:** TypeScript → SKILL.md files. See [ADR-004](adr/004-typescript-ssot.md).

### 3. Stack Enforcement

Centralized version management and package blocking.

| File | Purpose |
|------|---------|
| `stack/versions.ts` | Version SSOT for all dependencies |
| `stack/forbidden.ts` | Blocked packages with alternatives |

See [ADR-005](adr/005-stack-enforcement.md).

### 4. AST-grep Rules

YAML rules for TypeScript pattern enforcement.

```yaml
# rules/paragon/no-type-assertion.yml
id: no-type-assertion
language: typescript
severity: error
message: "Use Schema.decodeUnknown instead"
rule:
  pattern: "$EXPR as $TYPE"
```

See [ADR-006](adr/006-ast-grep-rules.md).

## Guard Categories

| Category | Count | Source | Blocks |
|----------|-------|--------|--------|
| Procedural | 17 | `guards/procedural.ts` | Bash, commits, DevOps |
| AST-grep | 21 | `rules/paragon/*.yml` | TypeScript patterns |
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
         │   ├── AST-grep rules (21)
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
| AST-grep rules | [006](adr/006-ast-grep-rules.md) | YAML pattern matching |
| Hook architecture | [007](adr/007-hook-architecture.md) | Pre-tool-use blocking |
| Nix management | [008](adr/008-nix-managed-config.md) | home-manager integration |

## Commands

```bash
cd config/quality
bun run generate   # Regenerate all adapters
bun run typecheck  # Validate types
bun run test       # Run tests
```

## Related

- Root: `/Users/hank/dotfiles/CLAUDE.md`
- MCP SSOT: `modules/home/apps/mcp.nix`
- Nix rebuild: `just switch`
