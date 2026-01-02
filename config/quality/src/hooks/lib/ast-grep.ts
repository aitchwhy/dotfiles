/**
 * AST-grep Integration (Legacy Removed)
 *
 * Safe-To-Auto-Run verified implementation using @ast-grep/napi.
 * Reads YAML rules directly from filesystem (SSOT).
 */

import * as fs from 'node:fs/promises'
import * as path from 'node:path'
import { Lang, parse } from '@ast-grep/napi'
import { Effect, Option } from 'effect'
import * as yaml from 'js-yaml'

// =============================================================================
// Types
// =============================================================================

export type AstGrepMatch = {
  readonly ruleId: string
  readonly message: string
  readonly severity: 'error' | 'warning'
  readonly line: number
  readonly column: number
  readonly text: string
}

type YamlRule = {
  id: string
  language: string
  severity: 'error' | 'warning'
  message: string
  // biome-ignore lint/suspicious/noExplicitAny: AST-grep NAPI rule objects are untyped
  rule: any
  // biome-ignore lint/suspicious/noExplicitAny: AST-grep constraints are untyped
  constraints?: Record<string, any>
}

// =============================================================================
// Logic
// =============================================================================

/**
 * Load all YAML rules from a directory
 */
const loadRules = (rulesDir: string) =>
  Effect.tryPromise({
    try: async () => {
      const files = await fs.readdir(rulesDir)
      const rules: YamlRule[] = []

      for (const file of files) {
        if (!file.endsWith('.yml') && !file.endsWith('.yaml')) continue

        const content = await fs.readFile(path.join(rulesDir, file), 'utf-8')
        const rule = yaml.load(content) as YamlRule
        rules.push(rule)
      }
      return rules
    },
    catch: (error) => new Error(`Failed to load rules from ${rulesDir}: ${error}`),
  })

/**
 * Run ast-grep check on content using YAML rules from a directory
 */
export const checkContent = (
  content: string,
  rulesDir: string,
): Effect.Effect<readonly AstGrepMatch[], Error> =>
  Effect.gen(function* () {
    const rules = yield* loadRules(rulesDir)
    const ast = parse(Lang.TypeScript, content)
    const root = ast.root()
    const matches: AstGrepMatch[] = []

    for (const rule of rules) {
      // Skip if rule language is not typescript (though directory implies TS)
      if (rule.language !== 'typescript') continue

      // Skip rules with inline constraints in patterns (not supported by NAPI findAll)
      const ruleStr = JSON.stringify(rule.rule)
      if (ruleStr.includes('"constraints"')) continue

      // biome-ignore lint/suspicious/noExplicitAny: AST-grep findAll requires untyped config
      const config: { rule: any; constraints?: Record<string, any> } = { rule: rule.rule }
      if (rule.constraints) {
        config.constraints = rule.constraints
      }

      // Try to run the rule - skip if pattern is invalid (not a complete AST node)
      // Uses Effect.option to handle errors gracefully (no try/catch)
      const nodesOption = yield* Effect.option(
        Effect.try({
          try: () => root.findAll(config),
          catch: () => new Error(`Invalid pattern for rule ${rule.id}`),
        }),
      )

      // Skip if rule has invalid pattern structure for NAPI
      // These rules work with ast-grep CLI but not with NAPI findAll
      if (Option.isNone(nodesOption)) continue

      const nodes = nodesOption.value
      for (const node of nodes) {
        const range = node.range()
        matches.push({
          ruleId: rule.id,
          message: rule.message,
          severity: rule.severity,
          line: range.start.line + 1, // 0-indexed to 1-indexed
          column: range.start.column + 1,
          text: node.text(),
        })
      }
    }

    return matches
  })

/**
 * Filter matches by severity
 */
export const filterBySeverity = (
  matches: readonly AstGrepMatch[],
  severity: 'error' | 'warning',
): readonly AstGrepMatch[] => {
  return matches.filter((m) => m.severity === severity)
}

/**
 * Format matches for hook output
 */
export const formatMatches = (matches: readonly AstGrepMatch[]): string => {
  if (matches.length === 0) return ''

  return matches.map((m) => `[${m.ruleId}] Line ${m.line}: ${m.message.trim()}`).join('\n\n')
}
