import type { SkillDefinition } from '../schemas'
import { SkillName } from '../schemas'

export const mcpOptimizationSkill: SkillDefinition = {
  frontmatter: {
    name: SkillName('mcp-optimization'),
    description:
      'MCP server usage patterns for token efficiency. When to use each server, caching strategies, session-type budgets.',
    allowedTools: ['mcp__*'],
    tokenBudget: 600,
  },
  sections: [
    {
      heading: 'Overview',
      content: `# MCP Server Optimization`,
    },
    {
      heading: 'Available Servers',
      content: `| Server | Purpose | Token Cost | When to Use |
|--------|---------|------------|-------------|
| \`ref\` | Library docs (SOTA) | Very Low | Before new library usage (60-95% fewer tokens) |
| \`ast-grep\` | AST-based search | Low | Code pattern matching |
| \`linear\` | Project management (SSE) | Low | Issue tracking, project queries, team ops |`,
    },
    {
      heading: 'Token Budget by Session Type',
      content: `| Session Type | Target Budget | Strategy |
|--------------|---------------|----------|
| Quick fix | <5k tokens | No MCP, minimal context |
| Feature dev | 10-20k tokens | Targeted repomix, selective skills |
| Architecture | 30-50k tokens | Full repomix, sequential thinking |
| Audit/review | 50-100k tokens | Comprehensive (justified by scope) |`,
    },
    {
      heading: 'Ref Patterns',
      content: `### SOTA Documentation Search

Ref.tools provides 60-95% fewer tokens than alternatives through:
- Context-aware deduplication (same docs not repeated in session)
- Focused snippets instead of full pages
- Version-specific documentation

\`\`\`typescript
// Search for documentation
mcp__ref__search({
  query: "Effect Layer composition patterns",
  library: "effect-ts"  // optional: focus on specific library
})
\`\`\`

### Token Efficiency Comparison

| Approach | Tokens | Notes |
|----------|--------|-------|
| WebFetch full page | 5-20k | Includes nav, footer, unrelated |
| context7 (deprecated) | 2-5k | Better but verbose |
| **ref** | 0.5-2k | Focused, deduplicated |`,
    },
    {
      heading: 'Repomix Patterns',
      content: `### Targeted Packing (Preferred)

\`\`\`bash
# API changes only
repomix pack . --include "src/routes/**,src/adapters/**"

# Frontend only
repomix pack . --include "src/components/**,src/pages/**"

# Config only
repomix pack . --include "*.nix,*.json,*.toml"
\`\`\`

### When to Use Compression

| Scenario | Compression |
|----------|-------------|
| Large codebase (>50k lines) | Enable |
| Focused feature work | Disable |
| Full audit | Enable |
| Quick reference | Disable |

### Incremental Analysis

\`\`\`
1. pack_codebase → returns output_id
2. grep_repomix_output(output_id, pattern) → targeted search
3. read_repomix_output(output_id, startLine, endLine) → detailed view
\`\`\``,
    },
    {
      heading: 'AST-Grep Patterns',
      content: `### Code Pattern Search

\`\`\`yaml
# Find all Effect.gen usages
mcp__ast-grep__find_code({
  pattern: "Effect.gen(function* () { $$$BODY })",
  language: "typescript"
})

# Find any type violations
mcp__ast-grep__find_code_by_rule({
  yaml: "id: any-type\\nlanguage: ts\\nrule:\\n  pattern: ': any'"
})
\`\`\`

### Rewrite Operations

\`\`\`typescript
// Replace console.log with logger
mcp__ast-grep__rewrite_code({
  pattern: "console.log($ARG)",
  replacement: "logger.info($ARG)",
  auto_apply: true
})
\`\`\``,
    },
    {
      heading: 'Anti-Patterns',
      content: `| Anti-Pattern | Correct Approach |
|--------------|------------------|
| Pack entire codebase for small task | Use targeted \`--include\` patterns |
| Multiple ref calls for same topic | Ref auto-deduplicates in session |
| Repomix without grep | Use grep_repomix_output for search |
| Full page WebFetch for docs | Use ref (60-95% fewer tokens) |`,
    },
    {
      heading: 'Cost Optimization Checklist',
      content: `- [ ] Use native tools (Read/Write) instead of MCP filesystem
- [ ] Use ref for docs (60-95% fewer tokens than alternatives)
- [ ] Use ast-grep for structural code pattern search
- [ ] Use linear for issue tracking instead of manual browser lookups`,
    },
  ],
}
