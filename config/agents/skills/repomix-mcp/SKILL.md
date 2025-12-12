---
name: repomix-mcp
description: Repomix MCP server tool reference. Pack codebases, search packed output, generate skills.
allowed-tools: mcp__repomix__*
---

# Repomix MCP Server (20.2k stars)

AI-optimized codebase packaging with ~70% token compression via Tree-sitter.

## When to Use

- Before major refactoring (need full codebase context)
- Architecture documentation generation
- When context window is constrained
- Analyzing unfamiliar codebases
- Creating reference skills from existing code

## Tools

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

## Configuration

Use `repomix.config.json` in project root:

```json
{
  "output": {
    "compress": true,
    "style": "xml"
  },
  "include": ["src/**/*.ts"],
  "ignore": {
    "useGitignore": true
  }
}
```
