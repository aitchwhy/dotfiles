import type { SkillDefinition } from '../schemas'
import { SkillName } from '../schemas'

export const refMcpSkill: SkillDefinition = {
  frontmatter: {
    name: SkillName('ref-mcp'),
    description: 'Ref.tools MCP server for SOTA documentation search (60-95% fewer tokens than alternatives).',
    allowedTools: ['mcp__ref__*'],
    tokenBudget: 500,
  },
  sections: [
    {
      heading: 'Overview',
      content: `# Ref.tools MCP Server

State-of-the-art documentation search with 60-95% fewer tokens than context7/fetch alternatives.

Key benefits:
- Context-aware deduplication (doesn't repeat docs in same session)
- Focused snippets instead of full pages
- 8,500+ libraries indexed with version-specific docs`,
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
use ref - how do I create an Effect Layer?
\`\`\``,
    },
    {
      heading: 'Tools',
      content: `### mcp__ref__search

Search for documentation on any library or topic.

\`\`\`typescript
mcp__ref__search({
  query: "Effect Layer composition",
  library: "effect-ts"  // optional: focus on specific library
})
\`\`\`

Returns focused documentation snippets with:
- Code examples
- API signatures
- Best practices`,
    },
    {
      heading: 'Usage Patterns',
      content: `### Before Implementing New Feature

\`\`\`
1. Search for library-specific patterns
2. Review returned snippets
3. Implement following documented patterns
\`\`\`

### Effect-TS (Critical)

The Effect API changes frequently. Training data is outdated.

**Always query ref before writing Effect code:**

\`\`\`typescript
mcp__ref__search({
  query: "Effect.gen usage patterns",
  library: "effect-ts"
})
\`\`\``,
    },
    {
      heading: 'Token Efficiency',
      content: `| Approach | Tokens | Notes |
|----------|--------|-------|
| WebFetch full page | 5-20k | Includes nav, footer, unrelated content |
| context7 | 2-5k | Better but still verbose |
| **ref** | 0.5-2k | Focused snippets, session deduplication |

Ref automatically deduplicates within a session - repeated queries for same docs return minimal tokens.`,
    },
  ],
}
