/**
 * Personas Generator
 *
 * Transforms PersonaDefinition → agent markdown files.
 */

import * as fs from 'node:fs/promises'
import * as path from 'node:path'
import { Effect } from 'effect'
import type { PersonaDefinition } from '../../schemas'

const generatePersonaMarkdown = (persona: PersonaDefinition): string => {
  const yaml = [
    '---',
    `name: ${persona.name}`,
    `description: ${persona.description}`,
    `model: ${persona.model}`,
    persona.color ? `color: ${persona.color}` : null,
    '---',
  ]
    .filter(Boolean)
    .join('\n')

  return `${yaml}\n\n# ${persona.name}\n\n${persona.systemPrompt}\n`
}

export const generatePersona = (persona: PersonaDefinition, outDir: string) =>
  Effect.gen(function* () {
    const markdown = generatePersonaMarkdown(persona)
    const personasDir = path.join(outDir, 'personas')
    const filePath = path.join(personasDir, `${persona.name}.md`)

    yield* Effect.tryPromise(() => fs.mkdir(personasDir, { recursive: true }))
    yield* Effect.tryPromise(() => fs.writeFile(filePath, markdown))

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
