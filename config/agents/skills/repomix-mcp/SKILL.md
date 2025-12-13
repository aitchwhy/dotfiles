---
name: repomix-mcp
description: Repomix MCP server tool reference. Pack codebases, search packed output, generate skills.
allowed-tools: mcp__repomix__*, Read, Bash
---

# Repomix MCP Server (20.2k stars)

AI-optimized codebase packaging with ~70% token compression via Tree-sitter.

## When to Use

- Before major refactoring (need full codebase context)
- Architecture documentation generation
- When context window is constrained
- Analyzing unfamiliar codebases
- Creating reference skills from existing code

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

### read_repomix_output

Read packed output with optional line range.

```
mcp__repomix__read_repomix_output({
  outputId: "abc123",
  startLine: 100,
  endLine: 200
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
# Pack current directory
repomix

# Pack with compression (smaller output via Tree-sitter)
repomix --compress

# Pack specific files only
repomix --include "src/**/*.ts,**/*.md"

# Ignore patterns
repomix --ignore "**/node_modules/**,**/*.log"

# Pack remote GitHub repository
repomix --remote user/repo --compress

# Specify output file
repomix --output context.xml

# Use config from different location
repomix --config path/to/repomix.config.json
```

### Justfile Shortcuts

```bash
just rx              # Pack current directory
just rx-ember        # Pack ember-platform with project config
just rx-dotfiles     # Pack dotfiles for config sharing
just rx-remote REPO  # Pack any GitHub repository
just rx-clip         # Pack and copy output path to clipboard
```

## Config File Best Practices

### Standard Project Config

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
      "sortByChanges": true,
      "sortByChangesMaxCommits": 100
    }
  }
}
```

**Why these defaults:**
- `parsableStyle: true` - Consistent XML structure for LLM parsing
- `compress: true` - Tree-sitter removes comments/whitespace, preserves semantics
- `sortByChanges: true` - Recently modified files appear first

### Include Patterns by Project Type

**Monorepo (NX/Turborepo)**:
```json
"include": ["apps/**/*.ts", "packages/**/*.ts", "libs/**/*.ts", "*.md", "*.json"]
```

**API/Backend**:
```json
"include": ["src/**/*.ts", "!src/**/*.test.ts", "*.md", "package.json"]
```

**Frontend**:
```json
"include": ["src/**/*.{ts,tsx}", "!**/*.test.*", "*.md", "tailwind.config.*"]
```

**Dotfiles/Config**:
```json
"include": ["**/*.nix", "**/*.lua", "**/*.kdl", "config/**/*.{json,md}", "justfile"]
```

### Common Ignore Patterns

```json
{
  "customPatterns": [
    "**/node_modules/**",
    "**/dist/**",
    "**/build/**",
    "**/*.log",
    "**/cloudflare-env.d.ts",
    "**/migrations/**",
    "**/*.css",
    ".wrangler/**",
    ".nx/**"
  ]
}
```

## Usage Patterns

### Explore Unfamiliar Codebase

```
1. pack_codebase with compress=true
2. grep_repomix_output to find patterns
3. read_repomix_output for specific sections
```

### Share Context Across Sessions

```
1. generate_skill to create reference skill
2. Skill persists in .claude/skills/
3. Future sessions can invoke skill
```

### Review Remote Code

```
1. pack_remote_repository for GitHub repos
2. Useful for dependency analysis
3. No local clone required
```

## Output Formats

| Format | Use Case |
|--------|----------|
| `xml` | Default, best for LLM parsing with parsableStyle |
| `markdown` | Human-readable, good for documentation |
| `plain` | Minimal formatting, raw content |

## Token Optimization

1. Use `compress: true` - Reduces tokens by 30-50%
2. Be specific with `include` patterns - Only pack what's needed
3. Set `topFilesLength: 10-15` - Limits file summary overhead
4. Ignore generated files (`migrations/**`, `*.css`, `dist/**`)

## Security

- `enableSecurityCheck: true` for production code (detects secrets)
- `enableSecurityCheck: false` for config-only repos (faster)
