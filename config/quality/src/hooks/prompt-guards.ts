#!/usr/bin/env bun

/**
 * UserPromptSubmit Hook — placeholder (CC-38).
 *
 * Fires on every user prompt submission in both harnesses (Claude Code +
 * Codex CLI). Intent: lightweight content-policy / prompt-shaping guards
 * (e.g., redact pasted secrets, reject malformed slash-command args).
 *
 * Phase 1 land is a no-op exit-0 so the hook can be wired in
 * `codex-definitions.ts` + `definitions.ts` without breaking sessions.
 * Future guards land additively here.
 *
 * Codex stdin (`UserPromptSubmit`):
 *   { hook_event_name, prompt, session_id, turn_id, cwd, model }
 * Claude stdin (`UserPromptSubmit`):
 *   { hook_event_name, session_id, prompt, cwd }
 *
 * `lib/hook-input-codex.ts::codexToClaudeShape` already projects the Codex
 * shape into the Claude shape for `UserPromptSubmit` (see the non-tool-event
 * pass-through branch).
 */

import { emitContinue } from './lib/hook-logging'

// No-op: consume nothing from stdin, just continue.
// Future content-policy guards will read stdin + branch on prompt content.
emitContinue()
process.exit(0)
