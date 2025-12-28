/**
 * Cursor Generator Adapter
 *
 * Generates .mdc (Markdown Component) files for Cursor IDE.
 * Output: .cursor/rules/*.mdc
 */

import * as fs from 'node:fs/promises'
import * as path from 'node:path'
import { Effect } from 'effect'
import type { SkillDefinition } from '../../schemas'

// Map our allowedTools to Cursor's globs if possible, or just generic globs
const SKILL_GLOBS: Record<string, string[]> = {
  'nix-patterns': ['*.nix', 'flake.lock'],
  'effect-ts': ['*.ts', '*.tsx'],
  'react-patterns': ['*.tsx', '*.jsx'],
  // Add more mappings as needed
}

const generateMdc = (skill: SkillDefinition): string => {
  const { frontmatter, sections } = skill

  // Cursor MDC Frontmatter
  // description: <short description>
  // globs: <file patterns>

  const globs = SKILL_GLOBS[frontmatter.name] || ['**/*']

  const content = sections.map((s) => `## ${s.heading}\n\n${s.content.trim()}`).join('\n\n')

  return `---
description: ${frontmatter.description}
globs: ${globs.join(', ')}
---

# ${frontmatter.name}

${content}
`
}

export const generateCursorRules = (skills: readonly SkillDefinition[], outDir: string) =>
  Effect.gen(function* () {
    const rulesDir = path.join(outDir, 'rules') // Cursor expects .cursor/rules
    yield* Effect.tryPromise(() => fs.mkdir(rulesDir, { recursive: true }))

    for (const skill of skills) {
      const markdown = generateMdc(skill)
      // Cursor uses .mdc extension
      const filename = `${skill.frontmatter.name}.mdc`
      const filePath = path.join(rulesDir, filename)

      yield* Effect.tryPromise(() => fs.writeFile(filePath, markdown))
      yield* Effect.log(`Generated Cursor Rule: ${filePath}`)
    }
  })
