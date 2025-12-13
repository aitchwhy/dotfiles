---
name: repomix-patterns
description: Patterns for codebase packing, analysis, and skill generation with Repomix.
allowed-tools: Read, Write, Edit
---

# Repomix Patterns

Usage patterns for AI-optimized codebase packaging. For MCP tool reference, see `repomix-mcp`.

## When to Use Repomix

| Scenario | Approach |
|----------|----------|
| Refactoring large module | Pack the module directory with compression |
| Understanding new codebase | Pack with `sortByChanges: true` for activity focus |
| Creating reference skill | Use `generate_skill` for persistent context |
| Analyzing dependencies | Pack `node_modules/package-name` selectively |
| Code review prep | Pack changed files only via git diff |

## Decision Matrix

```
Need full codebase context?
├── Yes → pack_codebase with compress=true
└── No → Need to search?
    ├── Yes → grep_repomix_output after packing
    └── No → Need persistent reference?
        ├── Yes → generate_skill
        └── No → Read files directly
```

## Output Format Selection

| Format | Best For | Token Efficiency |
|--------|----------|------------------|
| `xml` | LLM parsing, structured queries | High with parsableStyle |
| `markdown` | Human review, documentation | Medium |
| `json` | Programmatic processing | Low (verbose) |
| `plain` | Simple concatenation | Lowest |

**Default to `xml` with `parsableStyle: true`** for Claude interactions.

## Compression Strategy

### When to Enable Compression

```typescript
// Enable compression (compress: true) when:
// - Total source > 50KB
// - Token budget is constrained
// - Focus is on structure, not implementation details

// Disable compression when:
// - Debugging specific syntax
// - Comments contain important context
// - Working with config files (already minimal)
```

### Token Savings by Content Type

| Content Type | Compression Savings |
|--------------|---------------------|
| TypeScript source | 40-60% |
| React components | 35-50% |
| Config files | 10-20% |
| Markdown docs | 5-15% |

## Include Pattern Strategies

### By Project Type

**API/Backend**:
```json
{
  "include": [
    "src/**/*.ts",
    "!src/**/*.test.ts",
    "!src/**/*.spec.ts",
    "package.json",
    "tsconfig.json"
  ]
}
```

**Frontend**:
```json
{
  "include": [
    "src/**/*.{ts,tsx}",
    "!**/*.test.*",
    "!**/*.stories.*",
    "tailwind.config.*",
    "vite.config.*"
  ]
}
```

**Nix/Dotfiles**:
```json
{
  "include": [
    "**/*.nix",
    "flake.lock",
    "**/*.md",
    "config/**/*.json"
  ]
}
```

**Monorepo (focused)**:
```json
{
  "include": [
    "packages/core/src/**/*.ts",
    "packages/shared/src/**/*.ts",
    "package.json",
    "**/package.json"
  ]
}
```

## Skill Generation Patterns

### Creating a Reference Skill

```
1. Identify stable, referenceable code (patterns, not implementation)
2. Pack with focused includes
3. Generate skill with descriptive kebab-case name
4. Skill persists in .claude/skills/repomix-reference-{name}/
```

### Skill Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Project reference | `repomix-reference-{project}` | `repomix-reference-ember` |
| Pattern extraction | `{domain}-patterns` | `auth-patterns` |
| API documentation | `{service}-api-ref` | `stripe-api-ref` |

### Updating Skills

Skills are snapshots. To update:
1. Re-run `generate_skill` with same name
2. Previous version is overwritten
3. Consider versioning in name for stability

## Search Patterns

### Efficient grep_repomix_output Usage

```typescript
// Find all Effect.gen usages
pattern: "Effect\\.gen"

// Find type definitions
pattern: "^(type|interface)\\s+\\w+"

// Find exports
pattern: "^export\\s+(const|function|class)"

// Find imports from specific package
pattern: "from ['\"]effect['\"]"
```

### Context Lines Strategy

| Searching For | Context Lines |
|---------------|---------------|
| Function signatures | 0-2 |
| Implementation details | 5-10 |
| Usage examples | 3-5 |
| Error handling | 5-8 |

## Anti-Patterns

### Avoid

```typescript
// DON'T: Pack entire monorepo without filters
pack_codebase({ directory: "/project" })

// DON'T: Disable compression for large codebases
pack_codebase({ directory: "/large-project", compress: false })

// DON'T: Include generated files
include: ["**/*.ts"]  // Catches dist/, .d.ts files
```

### Prefer

```typescript
// DO: Focused includes
pack_codebase({
  directory: "/project",
  includePatterns: "src/**/*.ts,!**/*.test.ts",
  compress: true
})

// DO: Use ignorePatterns for common exclusions
pack_codebase({
  ignorePatterns: "node_modules/**,dist/**,coverage/**"
})
```

## Integration with Workflow

### Pre-Refactor Analysis

```
1. pack_codebase with target directory
2. grep_repomix_output for affected patterns
3. Identify dependencies and usages
4. Plan changes with full context
```

### Code Review Context

```
1. Get changed files: git diff --name-only main
2. Pack only changed files via includePatterns
3. Review with focused context
```

### Documentation Generation

```
1. Pack with markdown output style
2. Include only public API files
3. Use output as documentation draft base
```
