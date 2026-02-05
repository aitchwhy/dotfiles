/**
 * Skills Generator
 *
 * Transforms SkillDefinition → SKILL.md files.
 */

import { FileSystem } from '@effect/platform'
import yamlLib from 'js-yaml'
import * as path from 'node:path'
import { Effect } from 'effect'
import type { SkillDefinition } from '../../schemas'

const generateSkillMarkdown = (skill: SkillDefinition): string => {
  const { frontmatter, sections } = skill

  const fm: Record<string, unknown> = {
    name: frontmatter.name,
    description: frontmatter.description,
  }
  if (frontmatter.allowedTools) fm['allowed-tools'] = frontmatter.allowedTools.join(', ')
  if (frontmatter.tokenBudget) fm['token-budget'] = frontmatter.tokenBudget

  const yamlStr = yamlLib.dump(fm, { lineWidth: -1, quotingType: '"', forceQuotes: false })

  const content = sections.map((s) => `## ${s.heading}\n\n${s.content.trim()}`).join('\n\n')

  return `---\n${yamlStr}---\n\n# ${frontmatter.name}\n\n${content}\n`
}

export const generateSkill = (skill: SkillDefinition, outDir: string) =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const markdown = generateSkillMarkdown(skill)
    const skillDir = path.join(outDir, 'skills', skill.frontmatter.name)
    const filePath = path.join(skillDir, 'SKILL.md')

    yield* fs.makeDirectory(skillDir, { recursive: true })
    yield* fs.writeFileString(filePath, markdown)

    yield* Effect.log(`Generated: ${filePath}`)
    return filePath
  })

export const generateAllSkills = (skills: readonly SkillDefinition[], outDir: string) =>
  Effect.gen(function* () {
    const results: string[] = []
    for (const skill of skills) {
      const filePath = yield* generateSkill(skill, outDir)
      results.push(filePath)
    }
    return results
  })
