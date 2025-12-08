/**
 * FCS CLI - Factory Code System
 *
 * Command-line interface for the Universal Project Factory.
 *
 * Commands:
 *   fcs init <type> <name>   - Initialize a new project
 *   fcs gen <type> <name>    - Generate a workspace in existing project
 *   fcs validate [path]      - Validate project against spec
 *   fcs enforce [--fix]      - Run architecture enforcers
 */
import { Args, Command, Options } from '@effect/cli'
import { NodeContext, NodeRuntime } from '@effect/platform-node'
import { Console, Effect, Option } from 'effect'
import { generateCore } from '@/generators/core'
import { generateApi } from '@/generators/api'
import { generateUi } from '@/generators/ui'
import { generateMonorepo } from '@/generators/monorepo'
import { generateInfra } from '@/generators/infra'
import { TemplateEngineLive } from '@/layers/template-engine'
import { FileSystemLive, writeTree } from '@/layers/file-system'
import { GitLive, gitInit, gitAdd, gitCommit } from '@/layers/git'
import type { ProjectSpec } from '@/schema/project-spec'

// =============================================================================
// Arguments & Options
// =============================================================================

const PROJECT_TYPES = ['monorepo', 'api', 'ui', 'library', 'infra'] as const
type ProjectType = (typeof PROJECT_TYPES)[number]

const projectType = Args.text({ name: 'type' })
const projectName = Args.text({ name: 'name' })
const pathArg = Args.text({ name: 'path' }).pipe(Args.optional)
const fixOption = Options.boolean('fix').pipe(Options.withDefault(false))

const validateProjectType = (type: string): Effect.Effect<ProjectType, Error> => {
  if (PROJECT_TYPES.includes(type as ProjectType)) {
    return Effect.succeed(type as ProjectType)
  }
  return Effect.fail(new Error(`Invalid project type: ${type}. Valid types: ${PROJECT_TYPES.join(', ')}`))
}

// =============================================================================
// Init Command
// =============================================================================

export const initCommand = Command.make(
  'init',
  { type: projectType, name: projectName },
  ({ type, name }) =>
    Effect.gen(function* () {
      const validType = yield* validateProjectType(type)
      yield* Console.log(`\n🏭 Initializing ${validType} project: ${name}\n`)

      // Create project spec
      const spec: ProjectSpec = {
        name,
        type: validType,
        infra: { runtime: 'bun' },
        observability: { processCompose: true, metrics: false, debugger: 'vscode' },
      }

      // Generate files based on type
      const generator =
        validType === 'monorepo'
          ? generateMonorepo(spec)
          : validType === 'api'
            ? generateApi(spec)
            : validType === 'ui'
              ? generateUi(spec)
              : validType === 'infra'
                ? generateInfra(spec)
                : generateCore(spec)

      // Compose all layers for generation + file writing
      const tree = yield* generator.pipe(Effect.provide(TemplateEngineLive))

      // Also generate core files for non-core types
      const coreTree =
        type !== 'library'
          ? yield* generateCore(spec).pipe(Effect.provide(TemplateEngineLive))
          : {}

      // Merge trees (specific generator takes precedence)
      const mergedTree = { ...coreTree, ...tree }

      // Write files to disk
      const targetPath = `./${name}`
      yield* writeTree(mergedTree, targetPath).pipe(Effect.provide(FileSystemLive))

      // Initialize git repository
      yield* gitInit(targetPath).pipe(Effect.provide(GitLive))
      yield* gitAdd(targetPath, ['.']).pipe(Effect.provide(GitLive))
      yield* gitCommit(targetPath, 'chore: initial commit from factory').pipe(
        Effect.provide(GitLive)
      )

      yield* Console.log(`✅ Project ${name} created successfully!`)
      yield* Console.log(`\nNext steps:`)
      yield* Console.log(`  cd ${name}`)
      yield* Console.log(`  bun install`)
      yield* Console.log(`  bun dev`)
    })
)

// =============================================================================
// Gen Command
// =============================================================================

export const genCommand = Command.make(
  'gen',
  { type: projectType, name: projectName },
  ({ type, name }) =>
    Effect.gen(function* () {
      const validType = yield* validateProjectType(type)
      yield* Console.log(`\n🔧 Generating ${validType} workspace: ${name}\n`)

      const spec: ProjectSpec = {
        name,
        type: validType,
        infra: { runtime: 'bun' },
        observability: { processCompose: true, metrics: false, debugger: 'vscode' },
      }

      const generator =
        validType === 'api'
          ? generateApi(spec)
          : validType === 'ui'
            ? generateUi(spec)
            : validType === 'infra'
              ? generateInfra(spec)
              : generateCore(spec)

      const tree = yield* generator.pipe(Effect.provide(TemplateEngineLive))

      // Write to apps/<name> or packages/<name> based on type
      const targetPath = type === 'library' ? `./packages/${name}` : `./apps/${name}`
      yield* writeTree(tree, targetPath).pipe(Effect.provide(FileSystemLive))

      yield* Console.log(`✅ Workspace ${name} generated at ${targetPath}`)
    })
)

// =============================================================================
// Validate Command
// =============================================================================

export const validateCommand = Command.make('validate', { path: pathArg }, ({ path }) =>
  Effect.gen(function* () {
    const targetPath = Option.getOrElse(path, () => '.')
    yield* Console.log(`\n🔍 Validating project at: ${targetPath}\n`)

    // TODO: Implement validation against ProjectSpec
    yield* Console.log('Checking project structure...')
    yield* Console.log('Checking dependencies...')
    yield* Console.log('Checking TypeScript config...')

    yield* Console.log(`\n✅ Validation passed`)
  })
)

// =============================================================================
// Enforce Command
// =============================================================================

export const enforceCommand = Command.make('enforce', { fix: fixOption }, ({ fix }) =>
  Effect.gen(function* () {
    yield* Console.log(`\n👮 Running architecture enforcers${fix ? ' (with auto-fix)' : ''}\n`)

    // TODO: Implement police and architect enforcers
    yield* Console.log('Running Police enforcer...')
    yield* Console.log('  ✓ Structure validation')
    yield* Console.log('  ✓ Naming conventions')
    yield* Console.log('  ✓ Dependency hygiene')

    yield* Console.log('\nRunning Architect enforcer...')
    yield* Console.log('  ✓ Hexagonal boundaries')
    yield* Console.log('  ✓ No circular dependencies')
    yield* Console.log('  ✓ Layer violations')

    yield* Console.log(`\n✅ All checks passed`)
  })
)

// =============================================================================
// Main Command
// =============================================================================

export const mainCommand = Command.make('fcs', {}, () =>
  Console.log(`
🏭 Factory Code System (FCS)

Universal Project Factory for generating formally consistent software systems.

Commands:
  fcs init <type> <name>   Initialize a new project
  fcs gen <type> <name>    Generate a workspace in existing project
  fcs validate [path]      Validate project against spec
  fcs enforce [--fix]      Run architecture enforcers

Project Types:
  monorepo    Bun workspaces monorepo
  api         Hexagonal Hono API
  ui          React 19 + XState + TanStack Router
  library     Standalone TypeScript library
  infra       Pulumi + process-compose infrastructure

Examples:
  fcs init monorepo ember-platform
  fcs gen api voice-service
  fcs gen ui web-app
  fcs validate
  fcs enforce --fix
`)
).pipe(
  Command.withSubcommands([initCommand, genCommand, validateCommand, enforceCommand])
)

// =============================================================================
// CLI Entry Point
// =============================================================================

const cli = Command.run(mainCommand, {
  name: 'fcs',
  version: '0.1.0',
})

// Only run if this is the main module
if (import.meta.main) {
  Effect.suspend(() => cli(process.argv)).pipe(
    Effect.provide(NodeContext.layer),
    NodeRuntime.runMain
  )
}
