import type { SkillDefinition } from '../schemas'
import { SkillName } from '../schemas'

export const agentBrowserSkill: SkillDefinition = {
  frontmatter: {
    name: SkillName('agent-browser'),
    description:
      'Browser automation CLI for AI agents. Use for testing UI changes, validating frontend behavior, and debugging visual issues.',
    allowedTools: ['Bash', 'Read'],
    tokenBudget: 600,
  },
  sections: [
    {
      heading: 'Quick Reference',
      content: `### First-Time Setup (one-time)
\`\`\`bash
agent-browser install  # Downloads Chromium (~200MB)
\`\`\`

### Start Session
\`\`\`bash
agent-browser open http://localhost:3000
\`\`\`

### Get Page State (ALWAYS do this first)
\`\`\`bash
# Interactive elements only, compact, JSON for parsing
agent-browser snapshot -i -c --json

# Human-readable with depth limit
agent-browser snapshot -i -d 3
\`\`\`

### Element Actions (use @refs from snapshot)
\`\`\`bash
agent-browser click @e2
agent-browser fill @e3 "test@example.com"
agent-browser type @e4 "password123"
agent-browser hover @e5
agent-browser select @e6 "option-value"
\`\`\``,
    },
    {
      heading: 'Semantic Locators',
      content: `Use when @refs are unavailable:

\`\`\`bash
agent-browser find role button click
agent-browser find text "Submit" click
agent-browser find label "Email" fill "test@example.com"
agent-browser find testid "login-btn" click
\`\`\``,
    },
    {
      heading: 'Screenshots & Verification',
      content: `\`\`\`bash
agent-browser screenshot              # viewport
agent-browser screenshot --full       # full page
agent-browser screenshot ./test.png   # save to file
\`\`\``,
    },
    {
      heading: 'Wait Commands',
      content: `\`\`\`bash
agent-browser wait @e2                # wait for element
agent-browser wait 1000               # wait ms
agent-browser wait --text "Success"   # wait for text
agent-browser wait --load networkidle # wait for network
\`\`\``,
    },
    {
      heading: 'Session Management',
      content: `\`\`\`bash
agent-browser --session 1 open http://localhost:3000  # isolated session
agent-browser state save ./auth.json                   # persist cookies
agent-browser state load ./auth.json                   # restore state
\`\`\``,
    },
    {
      heading: 'Workflow Pattern',
      content: `1. \`agent-browser open <url>\`
2. \`agent-browser snapshot -i -c\` to see interactive elements
3. Perform actions using @refs
4. \`agent-browser screenshot\` to verify result
5. Repeat until verified

### Key Flags
| Flag | Purpose |
|------|---------|
| \`-i, --interactive\` | Only show interactive elements |
| \`-c, --compact\` | Minimal output format |
| \`-d, --depth <n>\` | Limit accessibility tree depth |
| \`--json\` | Machine-readable output |
| \`--session <n>\` | Isolated browser session |
| \`--headed\` | Show browser window |`,
    },
  ],
}
