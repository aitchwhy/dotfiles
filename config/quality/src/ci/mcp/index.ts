/**
 * MCP Server Smoke Tests
 *
 * Tests that MCP servers can start without crashing.
 */

import { Effect, Console, Schema } from 'effect'

// Parse environment at boundary
const EnvSchema = Schema.Struct({
  GITHUB_TOKEN: Schema.optional(Schema.String),
})

const env = Schema.decodeUnknownSync(EnvSchema)({
  GITHUB_TOKEN: process.env['GITHUB_TOKEN'],
})

interface McpServer {
  readonly name: string
  readonly cmd: string[]
  readonly env?: Record<string, string | undefined>
}

const MCP_SERVERS: McpServer[] = [
  { name: 'repomix', cmd: ['npx', '-y', 'repomix', '--mcp'] },
  { name: 'fetch', cmd: ['uvx', 'mcp-server-fetch'] },
  {
    name: 'github',
    cmd: ['npx', '-y', '@modelcontextprotocol/server-github'],
    env: { GITHUB_PERSONAL_ACCESS_TOKEN: env.GITHUB_TOKEN },
  },
]

const testServer = (server: McpServer): Effect.Effect<{ name: string; ok: boolean }> =>
  Effect.gen(function* () {
    yield* Console.log(`  Testing ${server.name}...`)

    const proc = Bun.spawn(server.cmd, {
      env: { ...process.env, ...server.env },
      stdout: 'pipe',
      stderr: 'pipe',
    })

    // Give it 8 seconds to start
    yield* Effect.sleep('8 seconds')

    // Check if still running (good) or crashed with error (bad)
    if (proc.exitCode === null) {
      // Still running - success
      proc.kill()
      yield* Console.log(`  ✅ ${server.name} started successfully`)
      return { name: server.name, ok: true }
    }

    if (proc.exitCode === 0) {
      // Clean exit - some MCP servers exit cleanly when idle
      yield* Console.log(`  ✅ ${server.name} exited cleanly`)
      return { name: server.name, ok: true }
    }

    yield* Console.error(`  ❌ ${server.name} crashed with code ${proc.exitCode}`)
    return { name: server.name, ok: false }
  }).pipe(
    Effect.catchAll((error) =>
      Effect.gen(function* () {
        yield* Console.error(`  ❌ ${server.name} failed to start: ${error}`)
        return { name: server.name, ok: false }
      }),
    ),
  )

/**
 * Run MCP smoke tests sequentially (they bind to ports)
 */
export const runMcpSmokeTests = Effect.gen(function* () {
  yield* Console.log('\n🔌 MCP Server Smoke Tests')
  yield* Console.log('─'.repeat(50))

  // Run sequentially to avoid port conflicts
  const results: { name: string; ok: boolean }[] = []
  for (const server of MCP_SERVERS) {
    const result = yield* testServer(server)
    results.push(result)
  }

  const passed = results.filter((r) => r.ok).length
  const failed = results.filter((r) => !r.ok).length
  const success = failed === 0

  yield* Console.log(`\nResults: ${passed} passed, ${failed} failed`)

  return { success, passed, failed, results }
})
