/**
 * Snapshot test: generator output is parseable TOML with required sections.
 *
 * Runs the generator into a tmpdir, parses the emitted config.toml, and
 * asserts the shape Codex CLI expects. Catches regressions like:
 *   - missing/extra brackets in [[hooks.X.hooks]] nesting
 *   - typos in mcp_servers / agents / features keys
 *   - drift between ALL_CODEX_HOOK_EVENTS and what's actually emitted
 */
import { readFileSync } from 'node:fs'
import * as os from 'node:os'
import * as path from 'node:path'
import { FileSystem } from '@effect/platform'
import { BunContext } from '@effect/platform-bun'
import TOML from '@iarna/toml'
import { Effect } from 'effect'
import { describe, expect, it } from 'vitest'
import { CODEX_HOOK_DEFINITIONS } from '../../hooks/codex-definitions'
import { generateCodexConfigFile } from './config-toml.generator'

const generateToTmp = () =>
  Effect.runPromise(
    Effect.gen(function* () {
      const fs = yield* FileSystem.FileSystem
      const tmp = path.join(
        os.tmpdir(),
        `codex-gen-test-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
      )
      yield* fs.makeDirectory(tmp, { recursive: true })
      const filePath = yield* generateCodexConfigFile(tmp)
      return filePath
    }).pipe(Effect.provide(BunContext.layer)),
  )

describe('codex config-toml generator', () => {
  it('produces parseable TOML', async () => {
    const filePath = await generateToTmp()
    // biome-ignore lint/suspicious/noExplicitAny: parsed TOML shape
    const config: any = TOML.parse(readFileSync(filePath, 'utf8'))
    expect(config).toBeTypeOf('object')
  })

  it('contains required top-level keys', async () => {
    const filePath = await generateToTmp()
    // biome-ignore lint/suspicious/noExplicitAny: parsed TOML shape
    const config: any = TOML.parse(readFileSync(filePath, 'utf8'))
    expect(config.model).toBeTypeOf('string')
    expect(config.model_provider).toBeTypeOf('string')
    expect(config.sandbox_mode).toBeTypeOf('string')
    expect(config.approval_policy).toBeTypeOf('string')
  })

  it('declares the ref MCP server', async () => {
    const filePath = await generateToTmp()
    // biome-ignore lint/suspicious/noExplicitAny: parsed TOML shape
    const config: any = TOML.parse(readFileSync(filePath, 'utf8'))
    expect(config.mcp_servers?.ref?.url).toMatch(/^https:\/\//)
    expect(config.mcp_servers?.ref?.bearer_token_env_var).toBe('REF_API_KEY')
  })

  it('emits hook blocks for every wired Codex event', async () => {
    const filePath = await generateToTmp()
    // biome-ignore lint/suspicious/noExplicitAny: parsed TOML shape
    const config: any = TOML.parse(readFileSync(filePath, 'utf8'))
    // Every event with at least one non-empty group in the SSOT must
    // appear in the emitted TOML. Empty events (Stop, PreCompact, etc.,
    // currently enumerated but not wired) are allowed to be absent.
    for (const [event, groups] of Object.entries(CODEX_HOOK_DEFINITIONS)) {
      if (!groups || groups.length === 0) continue
      const hasNonEmpty = groups.some((g: { hooks: readonly unknown[] }) => g.hooks.length > 0)
      if (!hasNonEmpty) continue
      expect(config.hooks?.[event]).toBeDefined()
    }
  })

  it('declares agents runtime caps', async () => {
    const filePath = await generateToTmp()
    // biome-ignore lint/suspicious/noExplicitAny: parsed TOML shape
    const config: any = TOML.parse(readFileSync(filePath, 'utf8'))
    expect(config.agents?.max_depth).toBeTypeOf('number')
    expect(config.agents?.max_threads).toBeTypeOf('number')
  })
})
