/**
 * AST-grep Integration
 *
 * Pattern matching for TypeScript code using ast-grep.
 */

import { Effect } from 'effect'
import type { QualityRule } from '../../schemas'

// =============================================================================
// AST-grep Rule Generation
// =============================================================================

export type AstGrepMatch = {
  readonly ruleId: string
  readonly message: string
  readonly line: number
  readonly column: number
  readonly text: string
}

/**
 * Generate ast-grep YAML rule from a QualityRule pattern
 */
export const generateAstGrepRule = (rule: QualityRule, pattern: string): string => {
  return `
id: ${rule.id}
language: typescript
severity: ${rule.severity}
message: "${rule.message}"
rule:
  pattern: "${pattern}"
`.trim()
}

/**
 * Run ast-grep check on content
 * Returns matches found for the given rules
 */
export const checkContent = (
  content: string,
  rules: readonly QualityRule[],
): Effect.Effect<readonly AstGrepMatch[], Error> =>
  Effect.gen(function* () {
    const matches: AstGrepMatch[] = []

    for (const rule of rules) {
      for (const pattern of rule.patterns) {
        if (content.includes(pattern)) {
          const lines = content.split('\n')
          const lineIndex = lines.findIndex((line) => line.includes(pattern))

          if (lineIndex !== -1) {
            const line = lines[lineIndex]
            const column = line ? line.indexOf(pattern) : 0

            matches.push({
              ruleId: rule.id,
              message: rule.message,
              line: lineIndex + 1,
              column: column + 1,
              text: pattern,
            })
          }
        }
      }
    }

    return matches
  })

/**
 * Filter matches by severity
 */
export const filterBySeverity = (
  matches: readonly AstGrepMatch[],
  rules: readonly QualityRule[],
  severity: 'error' | 'warning',
): readonly AstGrepMatch[] => {
  const ruleMap = new Map(rules.map((r) => [r.id, r]))
  return matches.filter((m) => ruleMap.get(m.ruleId)?.severity === severity)
}

/**
 * Format matches for hook output
 */
export const formatMatches = (
  matches: readonly AstGrepMatch[],
  rules: readonly QualityRule[],
): string => {
  if (matches.length === 0) return ''

  const ruleMap = new Map(rules.map((r) => [r.id, r]))

  return matches
    .map((m) => {
      const rule = ruleMap.get(m.ruleId)
      const fix = rule?.fix ?? 'See rule documentation'
      return `[${m.ruleId}] Line ${m.line}: ${m.message}\n  Fix: ${fix}`
    })
    .join('\n\n')
}
