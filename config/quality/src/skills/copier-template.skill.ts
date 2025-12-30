/**
 * Copier Template Skill
 *
 * SSOT project scaffolding with version injection.
 */

import type { SkillDefinition } from '../schemas'
import { SkillName } from '../schemas'

export const copierTemplateSkill: SkillDefinition = {
	frontmatter: {
		name: SkillName('copier-template'),
		description: 'Creating/updating SSOT projects with Copier',
		allowedTools: ['Read', 'Write', 'Edit', 'Bash', 'Grep'],
		tokenBudget: 500,
	},
	sections: [
		{
			heading: 'Creating New Projects',
			content: `
Use Copier to create projects from SSOT template:

\`\`\`bash
# Interactive mode
pipx run copier copy ~/dotfiles/config/quality/templates/copier-monorepo ./my-project --trust

# Non-interactive with data
pipx run copier copy ~/dotfiles/config/quality/templates/copier-monorepo ./my-project \\
  --data project_name=my-project \\
  --data include_api=true \\
  --data include_mobile=true \\
  --trust
\`\`\`
`,
		},
		{
			heading: 'Version Injection',
			content: `
Versions are injected at copy-time from SSOT (versions.ts):

1. \`build-versions.ts\` runs during \`copier copy\`
2. Imports STACK from versions.ts
3. Writes versions.json to template/
4. Templates reference \`{{ versions['package'] }}\`

NEVER hardcode versions in templates - always use SSOT.
`,
		},
		{
			heading: 'Template Questions',
			content: `
| Question | Type | Purpose |
|----------|------|---------|
| project_name | str | kebab-case name |
| scope | str | npm scope (without @) |
| include_api | bool | Effect HTTP API |
| include_web | bool | TanStack Router app |
| include_mobile | bool | Expo universal app |
| cloud_provider | choice | none/aws |
| database | choice | none/postgresql/turso |
| auth_provider | choice | none/better-auth |
`,
		},
		{
			heading: 'Updating Projects',
			content: `
\`\`\`bash
# Update existing project to latest template
cd my-project
pipx run copier update --trust
\`\`\`

The \`.copier-answers.yml\` file preserves your choices.
`,
		},
		{
			heading: 'Jinja Delimiters',
			content: `
- JSON files: Standard \`{{ }}\` delimiters
- TypeScript files: Custom \`[[ ]]\` and \`[% %]\` delimiters

This prevents conflicts with template literals.
`,
		},
	],
}
