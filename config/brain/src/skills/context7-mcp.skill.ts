import type { SkillDefinition } from '../schemas'
import { SkillName } from '../schemas'

export const context7McpSkill: SkillDefinition = {
  frontmatter: {
    name: SkillName('context7-mcp'),
    description: 'Context7 MCP server for fetching up-to-date library documentation.',
    allowedTools: ['mcp__context7__*'],
    tokenBudget: 500,
  },
  sections: [
    {
      heading: 'Overview',
      content: `# Context7 MCP Server (37.1k stars)

Up-to-date documentation for 8,500+ libraries. Prevents hallucinated APIs by providing current, version-specific docs.`,
    },
    {
      heading: 'When to Use',
      content: `- **Effect-TS**: APIs change frequently, training data outdated
- Any library where unsure of current API
- Before writing code with external imports
- When user asks "how do I use X?"
- Verifying function signatures and parameters`,
    },
    {
      heading: 'Trigger Phrase',
      content: `\`\`\`
use context7 - how do I create an Effect Layer?
\`\`\``,
    },
    {
      heading: 'Tools',
      content: `### resolve-library-id

Find Context7-compatible library ID from package name.

\`\`\`
mcp__context7__resolve-library-id({
  libraryName: "effect"
})
\`\`\`

Returns:
- Library ID (format: \`/org/project\`)
- Description
- Code snippet count
- Source reputation (High/Medium)
- Benchmark score (0-100)

### get-library-docs

Fetch documentation for a library.

\`\`\`
mcp__context7__get-library-docs({
  context7CompatibleLibraryID: "/effect-ts/effect",
  topic: "Layer",
  mode: "code",    // "code" for API/examples, "info" for concepts
  page: 1          // Pagination 1-10
})
\`\`\``,
    },
    {
      heading: 'Common Library IDs',
      content: `| Package | Library ID |
|---------|-----------|
| effect | \`/effect-ts/effect\` |
| @effect/platform | \`/effect-ts/effect\` |
| next.js | \`/vercel/next.js\` |
| react | \`/facebook/react\` |
| drizzle-orm | \`/drizzle-team/drizzle-orm\` |
| xstate | \`/statelyai/xstate\` |
| tailwindcss | \`/tailwindlabs/tailwindcss\` |`,
    },
    {
      heading: 'Usage Patterns',
      content: `### Before Implementing New Feature

\`\`\`
1. resolve-library-id to get correct ID
2. get-library-docs with relevant topic
3. Use mode="code" for implementation examples
\`\`\`

### Understanding Concepts

\`\`\`
1. get-library-docs with mode="info"
2. Paginate (page=2, page=3) for comprehensive coverage
\`\`\`

### Effect-TS (Critical)

The Effect API changes frequently. Training data is outdated.

**Always query context7 before writing Effect code:**

\`\`\`
mcp__context7__get-library-docs({
  context7CompatibleLibraryID: "/effect-ts/effect",
  topic: "Effect.gen"
})
\`\`\``,
    },
    {
      heading: 'Mode Selection',
      content: `| Mode | Use For |
|------|---------|
| \`code\` | Function signatures, API references, code examples |
| \`info\` | Architectural concepts, guides, best practices |`,
    },
  ],
}
