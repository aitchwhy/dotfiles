/**
 * Codex CLI hook output adapter.
 *
 * Claude Code accepts `{ decision: 'approve' | 'block' | 'skip', reason? }`
 * on stdout from hook scripts. Codex (v0.130+) parses the same JSON envelope
 * but only honors `decision: 'block'` — any other `decision` value is rejected
 * with a red "unsupported decision:<value>" notice in the TUI before "failing
 * open" (allowing the tool call). The notice is harmless but noisy: every
 * approve/skip emission from a passing guard surfaces as an error to the user.
 *
 * The symmetric counterpart to `hook-input-codex.ts`: that module projects
 * Codex stdin INTO the Claude shape; this module suppresses outbound emissions
 * that the Claude shape allows but Codex would reject.
 *
 * References:
 *   - https://developers.openai.com/codex/hooks (output schema)
 *   - Codex `codex-rs/exec/src/hook_runner.rs` (decision parser)
 *   - Linear CC-86
 *
 * Detection:
 *   `CODEX_HOME` is set by the `cx` recipe before launching Codex, so its
 *   presence is the canonical "we are running under Codex" signal. We do NOT
 *   peek at the input shape here because the hook may have already consumed
 *   stdin by the time output emission happens.
 */

export type SuppressibleDecision = {
  readonly decision: string
  readonly [key: string]: unknown
}

/**
 * True when the current process was launched under Codex.
 *
 * The `cx` recipe (modules/home/apps/codex.nix) exports `CODEX_HOME` before
 * exec'ing the Codex binary. Hook scripts inherit it via Codex's child-process
 * environment.
 */
export const isCodexOutputContext = (): boolean =>
  typeof process.env['CODEX_HOME'] === 'string' && process.env['CODEX_HOME'].length > 0

/**
 * True when the given hook decision should NOT be emitted to stdout under
 * Codex. Currently: `approve` and `skip` — both produce a red "unsupported
 * decision" notice in the Codex TUI even though they fail-open semantically.
 *
 * `block` is always emitted: Codex honors it and surfaces the `reason` to
 * the user as intended.
 *
 * Under Claude Code (no `CODEX_HOME`), this always returns false so the
 * existing emission behavior is preserved.
 */
export const shouldSuppressDecision = (decision: SuppressibleDecision): boolean => {
  if (!isCodexOutputContext()) return false
  return decision.decision === 'approve' || decision.decision === 'skip'
}
