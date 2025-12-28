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
| \`context7\` | Library docs | Low (cached) | Before new library usage |
| \`repomix\` | Codebase packing | High | Once per session for exploration |
| \`memory\` | Persistent knowledge | Low | Session start/end |
| \`sequential-thinking\` | Complex planning | Medium | Multi-step reasoning |
| \`fetch\` | URL content | Medium | External documentation |
| \`filesystem\` | File operations | Low | Prefer native Read/Write tools |
| \`github\` | Repository operations | Low | PR/issue management |
| \`playwright\` | Browser automation | Medium | E2E testing, web scraping |
| \`ast-grep\` | AST-based search | Low | Code pattern matching |`,
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
      heading: 'Context7 Patterns',
      content: `### Pre-fetch at Session Start

\`\`\`typescript
// Identify project dependencies
const deps = await readPackageJson();

// Pre-fetch docs for frequently used libraries
await Promise.all([
  mcp__context7__resolve-library-id({ libraryName: "effect" }),
  mcp__context7__resolve-library-id({ libraryName: "@effect/platform" }),
  mcp__context7__resolve-library-id({ libraryName: "drizzle-orm" }),
]);
\`\`\`

### Mode Selection

| Mode | Use For |
|------|---------|
| \`code\` | Function signatures, API references, examples |
| \`info\` | Architectural concepts, guides, best practices |

### Pagination Strategy

When context insufficient:
1. Try \`page=2\`, \`page=3\` with same topic
2. Narrow topic to specific API
3. Switch modes if conceptual vs implementation`,
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
      heading: 'Memory Server Optimization',
      content: `### Structured Entity Storage

\`\`\`typescript
// Prefer structured entities over free-form
mcp__memory__create_entities([{
  name: "auth-decision",
  entityType: "architecture-decision",
  observations: [
    "library: better-auth@1.4.6",
    "pattern: session-based",
    "location: src/auth/",
    "reason: Effect-compatible"
  ]
}]);
\`\`\`

### Query Patterns

| Need | Action |
|------|--------|
| Recall decision | \`open_nodes(["auth-decision"])\` |
| Search context | \`search_nodes("authentication")\` |
| Update learning | \`add_observations(...)\` |`,
    },
    {
      heading: 'Sequential Thinking Discipline',
      content: `### Use For

- Multi-file refactoring
- Bug investigation with multiple hypotheses
- Architecture decisions with trade-offs
- Complex implementation planning

### Skip For

- Single file edits
- Documentation updates
- Simple feature additions
- Trivial bug fixes (use TodoWrite instead)`,
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
| Multiple context7 calls per library | Cache library ID, paginate docs |
| Repomix without grep | Use grep_repomix_output for search |
| Sequential thinking for simple tasks | Use TodoWrite for task tracking |
| Memory for temporary data | Only store architectural decisions |`,
    },
    {
      heading: 'Cost Optimization Checklist',
      content: `- [ ] Use native tools (Read/Write) over MCP filesystem
- [ ] Pre-fetch context7 docs at session start
- [ ] Use targeted repomix includes
- [ ] Skip sequential thinking for trivial tasks
- [ ] Cache library IDs for repeated queries
- [ ] Use grep_repomix_output instead of full reads`,
    },
  ],
}
