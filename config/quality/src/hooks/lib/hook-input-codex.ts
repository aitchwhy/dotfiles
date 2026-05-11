/**
 * Codex CLI hook input adapter.
 *
 * Codex (v0.130+) and Claude Code emit different stdin JSON shapes to hook
 * scripts. This adapter projects Codex's shape into the Claude shape the
 * existing hook pipeline (`pre-tool-use.ts`, `post-tool-use.ts`,
 * `unified-polish.ts`, `session-init.ts`) already consumes.
 *
 * References:
 *   - https://developers.openai.com/codex/hooks
 *   - Codex `codex-rs/protocol/src/protocol.rs::HookEventName`
 *   - CC-60 Phase B doc (Linear)
 *
 * Codex input shape (PreToolUse / PostToolUse):
 *   {
 *     "hook_event_name": "PreToolUse" | "PostToolUse" | ...,
 *     "tool_name": "apply_patch" | "Bash" | <MCP tool name>,
 *     "tool_use_id": string,
 *     "tool_input": { ...tool-specific... },
 *     "tool_response"?: { ...PostToolUse only... },
 *     "turn_id": string,
 *     "session_id": string,
 *     "cwd"?: string,
 *     "model"?: string
 *   }
 *
 * For `apply_patch`, `tool_input.command` is the raw patch body
 * ("*** Begin Patch\n*** Update File: path\n@@\n...\n*** End Patch").
 *
 * For `Bash`, `tool_input` matches Claude shape: `{ command, description? }`.
 *
 * Claude shape (what existing hooks expect — see `effect-hook.ts`):
 *   {
 *     "hook_event_name": "PreToolUse" | ...,
 *     "session_id": string,
 *     "tool_name": "Edit" | "Write" | "MultiEdit" | "Bash" | ...,
 *     "tool_input": {
 *       file_path?, content?, new_string?, command?, description?, ...
 *     }
 *   }
 *
 * Mapping rules:
 *   - `apply_patch` keeps its name; matchers in `codex-definitions.ts`
 *     handle `^apply_patch$` instead of `^(Edit|Write|MultiEdit)$`.
 *   - The patch body is parsed to extract changed file paths; the FIRST
 *     changed path lands in `tool_input.file_path`, all paths land in the
 *     `CLAUDE_FILE_PATHS` env var (newline-joined) for `unified-polish.ts`.
 *   - `Bash` and MCP tool calls pass through with `tool_input` unchanged.
 *   - `turn_id` is dropped; `session_id` is kept.
 */

/**
 * Parse paths from an apply_patch body.
 *
 * Patch format:
 *   *** Begin Patch
 *   *** Update File: path/a.ts
 *   @@ ... @@
 *   ...
 *   *** Add File: path/b.ts
 *   ...
 *   *** Delete File: path/c.ts
 *   *** End Patch
 */
export function parseApplyPatchPaths(patchBody: string): readonly string[] {
  const paths: string[] = []
  const re = /^\*{3}\s+(?:Update|Add|Delete)\s+File:\s+(.+?)\s*$/gm
  for (const m of patchBody.matchAll(re)) {
    if (m[1]) paths.push(m[1])
  }
  return paths
}

export interface CodexHookInput {
  readonly hook_event_name: string
  readonly tool_name?: string
  readonly tool_use_id?: string
  readonly tool_input?: Record<string, unknown>
  readonly tool_response?: Record<string, unknown>
  readonly turn_id?: string
  readonly session_id?: string
  readonly cwd?: string
  readonly model?: string
  // SessionStart-only:
  readonly source?: 'startup' | 'resume' | 'clear'
  // UserPromptSubmit-only:
  readonly prompt?: string
  // Stop-only:
  readonly stop_hook_active?: boolean
  readonly last_assistant_message?: string
}

export interface ClaudeShapeToolInput {
  readonly file_path?: string | undefined
  readonly content?: string | undefined
  readonly new_string?: string | undefined
  readonly command?: string | undefined
  readonly description?: string | undefined
  readonly pattern?: string | undefined
  readonly glob?: string | undefined
  readonly path?: string | undefined
  readonly [k: string]: unknown
}

export interface ClaudeShapeInput {
  readonly hook_event_name: string
  readonly session_id: string
  readonly tool_name?: string | undefined
  readonly tool_input?: ClaudeShapeToolInput | undefined
  readonly tool_response?: Record<string, unknown> | undefined
  readonly cwd?: string | undefined
  readonly prompt?: string | undefined
}

/**
 * Side-effect: writes CLAUDE_FILE_PATHS env var (newline-joined) when the
 * incoming Codex event is an apply_patch. Returns the projected Claude-shape
 * input.
 *
 * Pure callers who want to inspect changed paths without env mutation should
 * call `parseApplyPatchPaths` directly.
 */
export function codexToClaudeShape(input: CodexHookInput): ClaudeShapeInput {
  const session_id = input.session_id ?? input.turn_id ?? 'unknown-session'

  // Non-tool events pass through largely unchanged.
  if (
    input.hook_event_name === 'SessionStart' ||
    input.hook_event_name === 'UserPromptSubmit' ||
    input.hook_event_name === 'Stop' ||
    input.hook_event_name === 'PreCompact' ||
    input.hook_event_name === 'PostCompact' ||
    input.hook_event_name === 'PermissionRequest'
  ) {
    return {
      hook_event_name: input.hook_event_name,
      session_id,
      cwd: input.cwd,
      prompt: input.prompt,
    }
  }

  // Tool events: PreToolUse / PostToolUse.
  const codexToolInput = input.tool_input ?? {}

  if (input.tool_name === 'apply_patch') {
    const patchBody = String(codexToolInput['command'] ?? codexToolInput['input'] ?? '')
    const paths = parseApplyPatchPaths(patchBody)
    if (paths.length > 0) {
      // CLAUDE_FILE_PATHS is comma-joined — matches the
      // `.split(',')` consumers in unified-polish.ts:26 and
      // enforce-packages.ts:38. Paths with commas are not supported (none
      // of the dotfiles or told paths contain commas).
      process.env['CLAUDE_FILE_PATHS'] = paths.join(',')
    }
    return {
      hook_event_name: input.hook_event_name,
      session_id,
      tool_name: 'apply_patch',
      tool_input: {
        // Project first changed path into Claude's file_path slot so the
        // existing Edit/Write logic in pre-tool-use.ts sees something.
        file_path: paths[0],
        // Keep the raw patch body under `content` so checks that scan content
        // (forbidden-package detection, etc.) work on package.json patches.
        content: patchBody,
        ...codexToolInput,
      },
      tool_response: input.tool_response,
      cwd: input.cwd,
    }
  }

  // Bash, Grep, MCP tools: tool_input shape already matches Claude's.
  return {
    hook_event_name: input.hook_event_name,
    session_id,
    tool_name: input.tool_name,
    tool_input: codexToolInput as ClaudeShapeToolInput,
    tool_response: input.tool_response,
    cwd: input.cwd,
  }
}

/**
 * Detect whether stdin JSON is in Codex shape (vs Claude shape).
 *
 * Cheap heuristic: Codex always includes `turn_id` or `tool_use_id` on
 * tool events; Claude uses `session_id` only. For non-tool events,
 * presence of `CODEX_HOME` in env is the tiebreaker.
 */
export function isCodexShape(input: unknown): input is CodexHookInput {
  if (typeof input !== 'object' || input === null) return false
  const v = input as Record<string, unknown>
  if (typeof v['turn_id'] === 'string') return true
  if (typeof v['tool_use_id'] === 'string') return true
  // Fallback: env var set by `cx` recipe.
  return typeof process.env['CODEX_HOME'] === 'string'
}
