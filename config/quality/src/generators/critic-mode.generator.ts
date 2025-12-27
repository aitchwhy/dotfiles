/**
 * Critic Mode Generator
 *
 * Generates critic-mode.md from the CRITIC_BEHAVIORS constant.
 * Output: human-readable markdown for Claude context.
 */

import * as fs from 'node:fs/promises'
import * as path from 'node:path'
import { Effect } from 'effect'
import { BEHAVIOR_COUNTS, CRITIC_BEHAVIORS } from '../critic-mode'
import type { CriticBehavior, CriticPhase } from '../critic-mode/schemas'

const PHASE_ORDER: readonly CriticPhase[] = ['planning', 'execution']

const PHASE_DESCRIPTIONS: Record<CriticPhase, string> = {
  planning: 'Before writing code - ensure understanding and scope',
  execution: 'During implementation - verify and validate',
}

const formatBehavior = (behavior: CriticBehavior): string => {
  return [
    `### ${behavior.title}`,
    '',
    `**Trigger**: ${behavior.trigger}`,
    '',
    `**Action**: ${behavior.action}`,
  ].join('\n')
}

const formatPhase = (phase: CriticPhase): string => {
  const behaviors = CRITIC_BEHAVIORS.filter((b) => b.phase === phase)
  const header = `## ${phase.charAt(0).toUpperCase() + phase.slice(1)} Phase`
  const description = `*${PHASE_DESCRIPTIONS[phase]}*`
  const content = behaviors.map(formatBehavior).join('\n\n')

  return [header, '', description, '', content].join('\n')
}

const generateMarkdown = (): string => {
  const header = [
    '# Critic Mode Protocol',
    '',
    'Structured self-review behaviors for metacognitive quality.',
    '',
    `**Total**: ${BEHAVIOR_COUNTS.total} behaviors`,
    `- Planning: ${BEHAVIOR_COUNTS.planning}`,
    `- Execution: ${BEHAVIOR_COUNTS.execution}`,
    '',
    '---',
    '',
  ].join('\n')

  const phases = PHASE_ORDER.map(formatPhase).join('\n\n---\n\n')

  return `${header + phases}\n`
}

export const generateCriticModeFile = (outDir: string) =>
  Effect.gen(function* () {
    const markdown = generateMarkdown()
    const filePath = path.join(outDir, 'critic-mode.md')

    yield* Effect.tryPromise(() => fs.writeFile(filePath, markdown))

    yield* Effect.log(`Generated: ${filePath} (${BEHAVIOR_COUNTS.total} behaviors)`)
    return filePath
  })
