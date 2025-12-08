---
name: repomix-patterns
description: Repomix codebase packaging for AI context. CLI patterns, config files, include/ignore optimization.
allowed-tools: Read, Bash
---

## Quick Usage

### CLI Commands

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

Place `repomix.config.json` in project root. Key settings:

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
    ".nx/**",
    "**/*.code-profile"
  ]
}
```

## MCP Integration

When using repomix MCP server (`pack_codebase` tool):

```
Tool: pack_codebase
Parameters:
  directory: /absolute/path/to/project
  compress: true
  includePatterns: "src/**/*.ts,**/*.md"
  ignorePatterns: "**/*.test.ts,**/dist/**"
  style: "xml"
```

**Response includes:**
- `totalFiles` - Number of files packed
- `totalTokens` - Token count for LLM context budgeting
- `directoryStructure` - Tree view of included files
- `outputFilePath` - Path to generated output file

## Output Formats

| Format | Use Case |
|--------|----------|
| `xml` | Default, best for LLM parsing with parsableStyle |
| `markdown` | Human-readable, good for documentation |
| `plain` | Minimal formatting, raw content |

## Security

- `enableSecurityCheck: true` for production code (detects secrets)
- `enableSecurityCheck: false` for config-only repos (faster)

## Token Optimization

1. Use `compress: true` - Reduces tokens by 30-50%
2. Be specific with `include` patterns - Only pack what's needed
3. Set `topFilesLength: 10-15` - Limits file summary overhead
4. Ignore generated files (`migrations/**`, `*.css`, `dist/**`)
