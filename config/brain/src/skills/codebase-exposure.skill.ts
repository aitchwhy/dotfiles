import type { SkillDefinition } from '../schemas'
import { SkillName } from '../schemas'

export const codebaseExposureSkill: SkillDefinition = {
  frontmatter: {
    name: SkillName('codebase-exposure'),
    description:
      'Automated codebase exposure patterns for Claude Desktop and Claude Code. Pack codebases, configure MCP servers, generate skills.',
    allowedTools: [
      'mcp__repomix__*',
      'mcp__filesystem__*',
      'mcp__github__*',
      'Read',
      'Write',
      'Bash',
    ],
    tokenBudget: 800,
  },
  sections: [
    {
      heading: 'Overview',
      content: `# Codebase Exposure Patterns

Automatically expose codebases to Claude Desktop and Claude Code for comprehensive AI analysis.`,
    },
    {
      heading: 'Architecture',
      content: `| Location | Purpose | Managed By |
|----------|---------|------------|
| \`~/dotfiles/config/agents/skills/\` | SSOT for all skills | Git-tracked |
| \`~/.claude/skills/\` | Symlinks for Claude Code | home-manager |
| \`~/dotfiles/modules/home/apps/claude.nix\` | MCP server definitions | nix-darwin |`,
    },
    {
      heading: 'Exposure Methods',
      content: `| Method | Best For | Setup Effort |
|--------|----------|--------------|
| Repomix pack | One-time analysis, code review | Low |
| Repomix skill | Persistent reference, team sharing | Medium |
| MCP Filesystem | Real-time local access | Already configured |
| MCP GitHub | Remote repo access | Already configured |`,
    },
    {
      heading: 'Quick Commands',
      content: `### Pack Current Directory
\`\`\`bash
repomix --style xml --compress
\`\`\`

### Generate Skill from Codebase
\`\`\`
mcp__repomix__generate_skill({
  directory: "/path/to/project",
  skillName: "project-reference",
  compress: true
})
\`\`\``,
    },
    {
      heading: 'repomix.config.ts Template',
      content: `For Python/data analytics projects:

\`\`\`typescript
import { defineConfig } from 'repomix';

export default defineConfig({
  output: {
    style: 'xml',
    compress: false,
    showLineNumbers: true,
    git: { sortByChanges: true },
  },
  include: [
    'CLAUDE.md', 'README.md', 'justfile', 'flake.nix',
    '**/pipeline/**/*.py',
    '**/config/**/*.yaml',
    '**/pyproject.toml',
  ],
  ignore: {
    customPatterns: [
      '**/data/**', '**/snapshots/**',
      '**/__pycache__/**', 'uv.lock',
    ],
  },
});
\`\`\``,
    },
    {
      heading: 'Adding New MCP Servers',
      content: `Edit \`~/dotfiles/modules/home/apps/claude.nix\`:

\`\`\`nix
mcpServerDefs = {
  # ... existing servers ...
  my-new-server = {
    package = "@company/mcp-server";
    args = [ ];
  };
};
\`\`\`

Then run: \`just rebuild\``,
    },
    {
      heading: 'Adding New Skills',
      content: `1. Create: \`~/dotfiles/config/agents/skills/my-skill/SKILL.md\`
2. Add symlink to \`~/dotfiles/config/agents/nix/agents.nix\`:
   \`\`\`nix
   ".claude/skills/my-skill".source =
     config.lib.file.mkOutOfStoreSymlink "\${agentsDir}/skills/my-skill";
   \`\`\`
3. Run: \`just rebuild\``,
    },
    {
      heading: 'Integration with PARAGON',
      content: `All exposed codebases should comply with:
- Guard 5: No \`any\` types
- Guard 6: No \`z.infer<>\`
- Guard 7: No mock patterns
- Guard 13: No assumption language`,
    },
  ],
}
