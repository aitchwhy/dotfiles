---
name: repomix
description: Repomix MCP server tools and patterns. Pack codebases for AI analysis, generate skills, optimize token usage.
allowed-tools: mcp__repomix__*, Read, Bash, Write, Edit
token-budget: 700
---

## When to Use

| Scenario | Approach |
|----------|----------|
| Refactoring large module | Pack the module directory with compression |
| Understanding new codebase | Pack with `sortByChanges: true` for activity focus |
| Creating reference skill | Use `generate_skill` for persistent context |
| Code review prep | Pack changed files only via includePatterns |

## MCP Tools

### pack_codebase

Pack a local directory into AI-analyzable output.

```
mcp__repomix__pack_codebase({
  directory: "/absolute/path",
  compress: true,              // Enable Tree-sitter compression
  includePatterns: "**/*.ts",  // Fast-glob patterns
  ignorePatterns: "test/**",
  style: "xml"                 // xml | markdown | json | plain
})
```

### pack_remote_repository

Pack a GitHub repository without cloning.

```
mcp__repomix__pack_remote_repository({
  remote: "owner/repo",        // or full GitHub URL
  compress: true,
  includePatterns: "src/**",
  style: "xml"
})
```

### grep_repomix_output

Search packed output using JavaScript RegExp.

```
mcp__repomix__grep_repomix_output({
  outputId: "abc123",          // ID from pack operation
  pattern: "Effect\\.gen",     // RegExp pattern
  contextLines: 3,
  ignoreCase: true
})
```

### generate_skill

Create Claude skill from codebase.

```
mcp__repomix__generate_skill({
  directory: "/path/to/project",
  skillName: "my-project-ref",  // kebab-case
  compress: true
})
```

## CLI Commands

```bash
repomix                          # Pack current directory
repomix --compress               # Smaller output via Tree-sitter
repomix --include "src/**/*.ts"  # Pack specific files only
repomix --remote user/repo       # Pack GitHub repository
repomix --output context.xml     # Specify output file
```

### Justfile Shortcuts

```bash
just rx              # Pack current directory
just rx-copy         # Pack and copy to clipboard
just rx-remote REPO  # Pack any GitHub repository
```

## Include Patterns by Project Type

**API/Backend**:
```json
"include": ["src/**/*.ts", "!src/**/*.test.ts", "package.json"]
```

**Frontend**:
```json
"include": ["src/**/*.{ts,tsx}", "!**/*.test.*", "tailwind.config.*"]
```

**Nix/Dotfiles**:
```json
"include": ["**/*.nix", "**/*.md", "config/**/*.json", "justfile"]
```

## Compression Strategy

| Content Type | Compression Savings |
|--------------|---------------------|
| TypeScript source | 40-60% |
| React components | 35-50% |
| Config files | 10-20% |
| Markdown docs | 5-15% |

**Enable compression** (`compress: true`) when:
- Total source > 50KB
- Token budget is constrained
- Focus is on structure, not implementation details

**Disable compression** when:
- Debugging specific syntax
- Comments contain important context

## Config File

Place `repomix.config.json` in project root:

```json
{
  "$schema": "https://repomix.com/schemas/latest/schema.json",
  "output": {
    "style": "xml",
    "parsableStyle": true,
    "compress": true,
    "topFilesLength": 10,
    "git": {
      "sortByChanges": true
    }
  }
}
```

## Search Patterns

```typescript
// Find all Effect.gen usages
pattern: "Effect\\.gen"

// Find type definitions
pattern: "^(type|interface)\\s+\\w+"

// Find exports
pattern: "^export\\s+(const|function|class)"
```

| Searching For | Context Lines |
|---------------|---------------|
| Function signatures | 0-2 |
| Implementation details | 5-10 |
| Usage examples | 3-5 |

## Anti-Patterns

```typescript
// DON'T: Pack entire monorepo without filters
pack_codebase({ directory: "/project" })

// DON'T: Disable compression for large codebases
pack_codebase({ directory: "/large-project", compress: false })

// DO: Focused includes with compression
pack_codebase({
  directory: "/project",
  includePatterns: "src/**/*.ts,!**/*.test.ts",
  compress: true
})
```

## Workflow Integration

### Pre-Refactor Analysis

1. Pack with target directory
2. `grep_repomix_output` for affected patterns
3. Identify dependencies and usages
4. Plan changes with full context

### Creating Reference Skills

1. Identify stable, referenceable code
2. Pack with focused includes
3. `generate_skill` with descriptive kebab-case name
4. Skill persists in `.claude/skills/`
