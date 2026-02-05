/**
 * Personas Generator
 *
 * Transforms PersonaDefinition → agent markdown files.
 */

import { FileSystem } from '@effect/platform'
import yaml from 'js-yaml'
import * as path from 'node:path'
import { Effect } from 'effect'
import type { PersonaDefinition } from '../../schemas'

const generatePersonaMarkdown = (persona: PersonaDefinition): string => {
  const frontmatter: Record<string, unknown> = {
    name: persona.name,
    description: persona.description,
    model: persona.model,
  }
  if (persona.color) frontmatter['color'] = persona.color

  const yamlStr = yaml.dump(frontmatter, { lineWidth: -1, quotingType: '"', forceQuotes: false })

  return `---\n${yamlStr}---\n\n# ${persona.name}\n\n${persona.systemPrompt}\n`
}

export const generatePersona = (persona: PersonaDefinition, outDir: string) =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const markdown = generatePersonaMarkdown(persona)
    const personasDir = path.join(outDir, 'personas')
    const filePath = path.join(personasDir, `${persona.name}.md`)

    yield* fs.makeDirectory(personasDir, { recursive: true })
    yield* fs.writeFileString(filePath, markdown)

    yield* Effect.log(`Generated: ${filePath}`)
    return filePath
  })

export const generateAllPersonas = (personas: readonly PersonaDefinition[], outDir: string) =>
  Effect.gen(function* () {
    const results: string[] = []
    for (const persona of personas) {
      const filePath = yield* generatePersona(persona, outDir)
      results.push(filePath)
    }
    return results
  })
