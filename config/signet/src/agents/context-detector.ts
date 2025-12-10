/**
 * Context Detector
 *
 * Evaluates the current context (prompt, files, git state, output) and
 * determines which agents/skills should be activated based on trigger rules.
 */
import { Effect } from 'effect'
import {
  type TriggerRule,
  type ContextSignal,
  getRulesByPriority,
} from './trigger-registry'

// =============================================================================
// Context Types
// =============================================================================

/** Current context state to evaluate */
export type Context = {
  readonly prompt?: string
  readonly activeFiles?: readonly string[]
  readonly recentOutput?: string
  readonly gitState?: {
    readonly hasStagedChanges: boolean
    readonly hasUnstagedChanges: boolean
    readonly hasMergeConflict: boolean
    readonly hasRebaseInProgress: boolean
  }
}

/** Result of context detection */
export type DetectionResult = {
  readonly matchedRules: readonly MatchedRule[]
  readonly agents: readonly string[]
  readonly skills: readonly string[]
}

export type MatchedRule = {
  readonly rule: TriggerRule
  readonly matchedSignals: readonly ContextSignal[]
}

// =============================================================================
// Signal Matchers
// =============================================================================

const matchPromptKeyword = (
  signal: Extract<ContextSignal, { type: 'prompt_keyword' }>,
  prompt: string | undefined
): boolean => {
  if (!prompt) return false
  const lowerPrompt = prompt.toLowerCase()
  return signal.keywords.some((kw) => lowerPrompt.includes(kw.toLowerCase()))
}

const matchFilePattern = (
  signal: Extract<ContextSignal, { type: 'file_pattern' }>,
  files: readonly string[] | undefined
): boolean => {
  if (!files || files.length === 0) return false

  return signal.patterns.some((pattern) => {
    // Convert glob pattern to regex
    // First escape dots, then handle glob patterns
    let regexStr = pattern.replace(/\./g, '\\.')
    regexStr = regexStr.replace(/\*\*/g, '.*')
    regexStr = regexStr.replace(/\*/g, '[^/]*')

    // If pattern doesn't start with ** or contain /, match filename only
    if (!pattern.startsWith('**') && !pattern.includes('/')) {
      // Match anywhere in path (e.g., *.test.ts matches src/auth.test.ts)
      regexStr = '(^|/)' + regexStr + '$'
    } else {
      regexStr = '^' + regexStr + '$'
    }

    const regex = new RegExp(regexStr)
    return files.some((file) => regex.test(file))
  })
}

const matchOutputPattern = (
  signal: Extract<ContextSignal, { type: 'output_pattern' }>,
  output: string | undefined
): boolean => {
  if (!output) return false
  return signal.patterns.some((pattern) => {
    try {
      const regex = new RegExp(pattern, 'i')
      return regex.test(output)
    } catch {
      return output.includes(pattern)
    }
  })
}

const matchGitState = (
  signal: Extract<ContextSignal, { type: 'git_state' }>,
  gitState: Context['gitState']
): boolean => {
  if (!gitState) return false

  return signal.states.some((state) => {
    switch (state) {
      case 'staged_changes':
        return gitState.hasStagedChanges
      case 'unstaged_changes':
        return gitState.hasUnstagedChanges
      case 'merge_conflict':
        return gitState.hasMergeConflict
      case 'rebase_in_progress':
        return gitState.hasRebaseInProgress
    }
  })
}

/** Check if a single signal matches the context */
const matchSignal = (signal: ContextSignal, context: Context): boolean => {
  switch (signal.type) {
    case 'prompt_keyword':
      return matchPromptKeyword(signal, context.prompt)
    case 'file_pattern':
      return matchFilePattern(signal, context.activeFiles)
    case 'output_pattern':
      return matchOutputPattern(signal, context.recentOutput)
    case 'git_state':
      return matchGitState(signal, context.gitState)
    case 'always':
      return true
  }
}

// =============================================================================
// Rule Matching
// =============================================================================

/** Check if a rule matches the context (any signal match = rule match) */
const matchRule = (rule: TriggerRule, context: Context): MatchedRule | null => {
  const matchedSignals = rule.signals.filter((signal) => matchSignal(signal, context))

  if (matchedSignals.length === 0) return null

  return { rule, matchedSignals }
}

// =============================================================================
// Detection Functions
// =============================================================================

/** Detect which rules match the current context */
export const detectContext = (context: Context): DetectionResult => {
  const sortedRules = getRulesByPriority()
  const matchedRules: MatchedRule[] = []
  const agentSet = new Set<string>()
  const skillSet = new Set<string>()

  for (const rule of sortedRules) {
    const match = matchRule(rule, context)
    if (match) {
      matchedRules.push(match)

      if (match.rule.target.type === 'agent') {
        agentSet.add(match.rule.target.name)
      } else {
        skillSet.add(match.rule.target.name)
      }
    }
  }

  return {
    matchedRules,
    agents: [...agentSet],
    skills: [...skillSet],
  }
}

/** Effect-wrapped detection */
export const detectContextEffect = (context: Context): Effect.Effect<DetectionResult> =>
  Effect.sync(() => detectContext(context))

/** Get only agents from detection */
export const detectAgents = (context: Context): readonly string[] => detectContext(context).agents

/** Get only skills from detection */
export const detectSkills = (context: Context): readonly string[] => detectContext(context).skills

// =============================================================================
// Git State Detection (helpers for building context)
// =============================================================================

/** Parse git status output to extract state */
export const parseGitStatus = (
  statusOutput: string
): NonNullable<Context['gitState']> => {
  const lines = statusOutput.split('\n').filter(Boolean)

  return {
    hasStagedChanges: lines.some(
      (line) =>
        line.startsWith('A ') ||
        line.startsWith('M ') ||
        line.startsWith('D ') ||
        line.startsWith('R ')
    ),
    hasUnstagedChanges: lines.some(
      (line) =>
        line.startsWith(' M') ||
        line.startsWith(' D') ||
        line.startsWith('??')
    ),
    hasMergeConflict: lines.some(
      (line) => line.startsWith('UU') || line.startsWith('AA') || line.startsWith('DD')
    ),
    hasRebaseInProgress: statusOutput.includes('rebase in progress'),
  }
}

// =============================================================================
// Export Index
// =============================================================================

export const ContextDetector = {
  detect: detectContext,
  detectEffect: detectContextEffect,
  detectAgents,
  detectSkills,
  parseGitStatus,
} as const
