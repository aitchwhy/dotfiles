/**
 * MCP Server Smoke Tests
 *
 * Tests that MCP servers can start without crashing.
 */

import { Effect, Console, Schema } from 'effect'

// Parse environment at boundary
const EnvSchema = Schema.Struct({
  GITHUB_TOKEN: Schema.optionalWith(Schema.String, { default: () => '' }),
})

const env = Schema.decodeUnknownSync(EnvSchema)({
  GITHUB_TOKEN: process.env['GITHUB_TOKEN'],
})

// Parse MCP server config at boundary with NonEmptyArray for cmd
const McpServerSchema = Schema.Struct({
  name: Schema.String,
  executable: Schema.String, // First element of cmd, guaranteed non-empty
  args: Schema.Array(Schema.String),
  envVars: Schema.optionalWith(Schema.Record({ key: Schema.String, value: Schema.String }), {
    default: () => ({}),
  }),
})

type McpServer = typeof McpServerSchema.Type

const MCP_SERVERS: McpServer[] = [
  { name: 'repomix', executable: 'npx', args: ['-y', 'repomix', '--mcp'], envVars: {} },
  { name: 'fetch', executable: 'uvx', args: ['mcp-server-fetch'], envVars: {} },
  {
    name: 'github',
    executable: 'npx',
    args: ['-y', '@modelcontextprotocol/server-github'],
    envVars: { GITHUB_PERSONAL_ACCESS_TOKEN: env.GITHUB_TOKEN },
  },
  {
    name: 'linear',
    executable: 'npx',
    args: ['-y', 'mcp-remote', 'https://mcp.linear.app/sse'],
    envVars: {},
  },
]

const testServer = (server: McpServer): Effect.Effect<{ name: string; ok: boolean }> =>
  Effect.gen(function* () {
    yield* Console.log(`  Testing ${server.name}...`)

    // Check if the executable is available (Bun.which returns null if not found)
    const executablePath = Bun.which(server.executable)
    if (executablePath === null) {
      yield* Console.log(`  ⏭️  ${server.name} skipped (${server.executable} not in PATH)`)
      return { name: server.name, ok: true }
    }

    const proc = Bun.spawn([server.executable, ...server.args], {
      env: { ...process.env, ...server.envVars },
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
