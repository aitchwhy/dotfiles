/**
 * Git Effect Layer
 *
 * Provides git operations as an Effect Layer.
 * Uses shell commands for git operations.
 */
import { Context, Effect, Layer } from 'effect'
import { exec } from 'node:child_process'
import { promisify } from 'node:util'

const execAsync = promisify(exec)

// =============================================================================
// Types
// =============================================================================

/**
 * Git service interface (Port)
 */
export interface GitService {
  readonly init: (path: string) => Effect.Effect<void, Error>
  readonly add: (path: string, files: readonly string[]) => Effect.Effect<void, Error>
  readonly commit: (path: string, message: string) => Effect.Effect<void, Error>
}

// =============================================================================
// Context Tag (Port Definition)
// =============================================================================

/**
 * Git Context Tag - the Port that generators depend on
 */
export class Git extends Context.Tag('Git')<Git, GitService>() {}

// =============================================================================
// Live Implementation (Adapter)
// =============================================================================

/**
 * Create the live Git service implementation
 */
const makeGitService = (): GitService => ({
  init: (path: string) =>
    Effect.tryPromise({
      try: () => execAsync('git init', { cwd: path }),
      catch: (e) => new Error(`git init failed in ${path}: ${e}`),
    }).pipe(Effect.asVoid),

  add: (path: string, files: readonly string[]) =>
    Effect.tryPromise({
      try: () => execAsync(`git add ${files.join(' ')}`, { cwd: path }),
      catch: (e) => new Error(`git add failed in ${path}: ${e}`),
    }).pipe(Effect.asVoid),

  commit: (path: string, message: string) =>
    Effect.tryPromise({
      try: async () => {
        // Set git config for the commit if not set
        await execAsync('git config user.email "factory@local" || true', { cwd: path })
        await execAsync('git config user.name "Factory" || true', { cwd: path })
        await execAsync(`git commit -m "${message.replace(/"/g, '\\"')}"`, { cwd: path })
      },
      catch: (e) => new Error(`git commit failed in ${path}: ${e}`),
    }).pipe(Effect.asVoid),
})

/**
 * GitLive - the live Layer providing the Git service
 */
export const GitLive = Layer.succeed(Git, makeGitService())

// =============================================================================
// Convenience Functions
// =============================================================================

/**
 * Initialize a git repository - requires Git in context
 */
export const gitInit = (path: string): Effect.Effect<void, Error, Git> =>
  Effect.flatMap(Git, (git) => git.init(path))

/**
 * Stage files - requires Git in context
 */
export const gitAdd = (
  path: string,
  files: readonly string[]
): Effect.Effect<void, Error, Git> =>
  Effect.flatMap(Git, (git) => git.add(path, files))

/**
 * Create a commit - requires Git in context
 */
export const gitCommit = (path: string, message: string): Effect.Effect<void, Error, Git> =>
  Effect.flatMap(Git, (git) => git.commit(path, message))
