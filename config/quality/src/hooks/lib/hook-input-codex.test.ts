/**
 * Codex → Claude hook input adapter tests.
 */
import { afterEach, describe, expect, it } from 'vitest'
import {
  type CodexHookInput,
  codexToClaudeShape,
  isCodexShape,
  parseApplyPatchPaths,
} from './hook-input-codex'

afterEach(() => {
  // Adapter mutates CLAUDE_FILE_PATHS as a side effect; clean up between tests.
  delete process.env['CLAUDE_FILE_PATHS']
})

describe('parseApplyPatchPaths', () => {
  it('extracts a single Update File path', () => {
    const patch = `*** Begin Patch
*** Update File: src/foo.ts
@@ -1,3 +1,4 @@
 line
+added
*** End Patch`
    expect(parseApplyPatchPaths(patch)).toEqual(['src/foo.ts'])
  })

  it('extracts multiple paths across Update/Add/Delete', () => {
    const patch = `*** Begin Patch
*** Update File: a.ts
@@
*** Add File: b.ts
@@
*** Delete File: c.ts
*** End Patch`
    expect(parseApplyPatchPaths(patch)).toEqual(['a.ts', 'b.ts', 'c.ts'])
  })

  it('returns empty array for non-patch input', () => {
    expect(parseApplyPatchPaths('just a bash command')).toEqual([])
  })
})

describe('codexToClaudeShape — apply_patch', () => {
  it('projects first changed path into tool_input.file_path and sets CLAUDE_FILE_PATHS', () => {
    const patch = `*** Begin Patch
*** Update File: src/a.ts
@@
*** Update File: src/b.ts
@@
*** End Patch`
    const input: CodexHookInput = {
      hook_event_name: 'PreToolUse',
      tool_name: 'apply_patch',
      tool_use_id: 'call_123',
      tool_input: { command: patch },
      turn_id: 'turn_abc',
      session_id: 'sess_xyz',
    }
    const out = codexToClaudeShape(input)
    expect(out.tool_name).toBe('apply_patch')
    expect(out.tool_input?.file_path).toBe('src/a.ts')
    expect(out.tool_input?.content).toBe(patch)
    expect(out.session_id).toBe('sess_xyz')
    expect(process.env['CLAUDE_FILE_PATHS']).toBe('src/a.ts,src/b.ts')
  })

  it('falls back to turn_id when session_id is missing', () => {
    const input: CodexHookInput = {
      hook_event_name: 'PreToolUse',
      tool_name: 'apply_patch',
      tool_input: { command: '*** Begin Patch\n*** Add File: x.ts\n*** End Patch' },
      turn_id: 'turn_only',
    }
    expect(codexToClaudeShape(input).session_id).toBe('turn_only')
  })
})

describe('codexToClaudeShape — Bash + MCP pass-through', () => {
  it('keeps Bash tool_input unchanged', () => {
    const input: CodexHookInput = {
      hook_event_name: 'PreToolUse',
      tool_name: 'Bash',
      tool_input: { command: 'just check', description: 'flake check' },
      session_id: 's',
    }
    const out = codexToClaudeShape(input)
    expect(out.tool_name).toBe('Bash')
    expect(out.tool_input?.command).toBe('just check')
    expect(out.tool_input?.description).toBe('flake check')
  })

  it('passes MCP tool_input through unchanged', () => {
    const input: CodexHookInput = {
      hook_event_name: 'PostToolUse',
      tool_name: 'mcp__ref__ref_search_documentation',
      tool_input: { query: 'codex hooks' },
      tool_response: { results: [] },
      session_id: 's',
    }
    const out = codexToClaudeShape(input)
    expect(out.tool_name).toBe('mcp__ref__ref_search_documentation')
    expect(out.tool_input?.['query']).toBe('codex hooks')
    expect(out.tool_response).toEqual({ results: [] })
  })
})

describe('codexToClaudeShape — non-tool events', () => {
  it('handles SessionStart without tool_input', () => {
    const input: CodexHookInput = {
      hook_event_name: 'SessionStart',
      source: 'startup',
      session_id: 's',
      cwd: '/tmp',
    }
    const out = codexToClaudeShape(input)
    expect(out.hook_event_name).toBe('SessionStart')
    expect(out.cwd).toBe('/tmp')
    expect(out.tool_input).toBeUndefined()
  })

  it('handles UserPromptSubmit', () => {
    const input: CodexHookInput = {
      hook_event_name: 'UserPromptSubmit',
      prompt: 'hello',
      session_id: 's',
    }
    expect(codexToClaudeShape(input).prompt).toBe('hello')
  })

  it('handles PreCompact / PostCompact (audit-discovered events)', () => {
    expect(
      codexToClaudeShape({ hook_event_name: 'PreCompact', session_id: 's' }).hook_event_name,
    ).toBe('PreCompact')
    expect(
      codexToClaudeShape({ hook_event_name: 'PostCompact', session_id: 's' }).hook_event_name,
    ).toBe('PostCompact')
  })

  it('handles Stop (CC-91 wiring; passthrough w/ session_id + cwd)', () => {
    const input: CodexHookInput = {
      hook_event_name: 'Stop',
      session_id: 's',
      cwd: '/tmp/work',
      stop_hook_active: false,
      last_assistant_message: 'done',
    }
    const out = codexToClaudeShape(input)
    expect(out.hook_event_name).toBe('Stop')
    expect(out.session_id).toBe('s')
    expect(out.cwd).toBe('/tmp/work')
    // Adapter intentionally drops stop_hook_active / last_assistant_message —
    // Stop-hook consumers (e.g., session-end unified-polish branch) read
    // CLAUDE_FILE_PATHS via env or re-scan the diff; they do not need the
    // last assistant message. Re-add the projection only if a future consumer
    // requires it.
    expect(out.tool_input).toBeUndefined()
  })

  it('PermissionRequest preserves tool_name + tool_input (CC-48 / CC-91)', () => {
    const input: CodexHookInput = {
      hook_event_name: 'PermissionRequest',
      session_id: 's',
      cwd: '/tmp/work',
      tool_name: 'Bash',
      tool_input: { command: 'rm -rf /' },
    }
    const out = codexToClaudeShape(input)
    // PermissionRequest re-uses the PreToolUse guard pipeline, so the
    // adapter routes it through the tool-event projection (not the
    // non-tool passthrough). Guards inspect tool_name + tool_input.
    expect(out.hook_event_name).toBe('PermissionRequest')
    expect(out.tool_name).toBe('Bash')
    expect(out.tool_input?.command).toBe('rm -rf /')
  })

  it('PermissionRequest for apply_patch projects file_path + CLAUDE_FILE_PATHS', () => {
    const patch =
      '*** Begin Patch\n*** Update File: src/a.ts\n@@\n*** Add File: src/b.ts\n*** End Patch'
    const input: CodexHookInput = {
      hook_event_name: 'PermissionRequest',
      session_id: 's',
      tool_name: 'apply_patch',
      tool_input: { command: patch },
    }
    const out = codexToClaudeShape(input)
    expect(out.tool_name).toBe('apply_patch')
    expect(out.tool_input?.file_path).toBe('src/a.ts')
    expect(process.env['CLAUDE_FILE_PATHS']).toBe('src/a.ts,src/b.ts')
  })
})

describe('isCodexShape', () => {
  it('detects via turn_id', () => {
    expect(isCodexShape({ turn_id: 'x' })).toBe(true)
  })

  it('detects via tool_use_id', () => {
    expect(isCodexShape({ tool_use_id: 'call_1' })).toBe(true)
  })

  it('falls back to CODEX_HOME env when neither marker present', () => {
    const prev = process.env['CODEX_HOME']
    process.env['CODEX_HOME'] = '/tmp/codex-test'
    try {
      expect(isCodexShape({ hook_event_name: 'SessionStart' })).toBe(true)
    } finally {
      if (prev === undefined) {
        delete process.env['CODEX_HOME']
      } else {
        process.env['CODEX_HOME'] = prev
      }
    }
  })

  it('rejects plain Claude shape when CODEX_HOME unset', () => {
    const prev = process.env['CODEX_HOME']
    delete process.env['CODEX_HOME']
    try {
      expect(
        isCodexShape({ hook_event_name: 'PreToolUse', session_id: 's', tool_name: 'Edit' }),
      ).toBe(false)
    } finally {
      if (prev !== undefined) process.env['CODEX_HOME'] = prev
    }
  })

  it('rejects non-object inputs', () => {
    expect(isCodexShape(null)).toBe(false)
    expect(isCodexShape('string')).toBe(false)
    expect(isCodexShape(42)).toBe(false)
  })
})
