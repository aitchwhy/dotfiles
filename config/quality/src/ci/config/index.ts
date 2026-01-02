/**
 * Config File Validation
 *
 * Validates JSON and YAML files in the repository.
 */

import { Effect, Console, Schema } from 'effect'
import { runCommand } from '../lib/command'

// Parse environment at boundary
const EnvSchema = Schema.Struct({
  DOTFILES: Schema.optionalWith(Schema.String, {
    default: () => `${process.env['HOME']}/dotfiles`,
  }),
})

const env = Schema.decodeUnknownSync(EnvSchema)({
  DOTFILES: process.env['DOTFILES'],
})

// Use fdfind on Ubuntu (fd-find package), fd on macOS
const fdCommand = process.platform === 'linux' ? 'fdfind' : 'fd'

// =============================================================================
// Types
// =============================================================================

interface FileValidationResult {
  readonly file: string
  readonly valid: boolean
}

const validateJson = Effect.gen(function* () {
  yield* Console.log('  Validating JSON files...')

  // Find JSON files (exclude node_modules, cursor/vscode JSONC)
  const findResult = yield* runCommand(fdCommand, [
    '-e',
    'json',
    '--exclude',
    'node_modules',
    '--exclude',
    '.git',
    '--exclude',
    '*cursor*',
    '--exclude',
    '*vscode*',
    env.DOTFILES,
  ])

  if (findResult.exitCode !== 0) {
    return true // No JSON files found is OK
  }

  const files = findResult.stdout.split('\n').filter(Boolean)

  // PARALLEL validation - all files checked simultaneously
  const results = yield* Effect.forEach(
    files,
    (file): Effect.Effect<FileValidationResult, never> =>
      Effect.gen(function* () {
        const checkResult = yield* runCommand('python3', ['-m', 'json.tool', file])
        return { file, valid: checkResult.exitCode === 0 }
      }),
    { concurrency: 'unbounded' },
  )

  // Report all invalid files
  const invalid = results.filter((r) => !r.valid)
  for (const r of invalid) {
    yield* Console.error(`    Invalid JSON: ${r.file}`)
  }

  return invalid.length === 0
})

const validateYaml = Effect.gen(function* () {
  yield* Console.log('  Validating YAML files...')

  // Find YAML files
  const findResult = yield* runCommand(fdCommand, [
    '-e',
    'yaml',
    '-e',
    'yml',
    '--exclude',
    'node_modules',
    '--exclude',
    '.git',
    env.DOTFILES,
  ])

  if (findResult.exitCode !== 0) {
    return true // No YAML files found is OK
  }

  const files = findResult.stdout.split('\n').filter(Boolean)

  // PARALLEL validation - all files checked simultaneously
  const results = yield* Effect.forEach(
    files,
    (file): Effect.Effect<FileValidationResult, never> =>
      Effect.gen(function* () {
        const checkResult = yield* runCommand('python3', [
          '-c',
          `import yaml; yaml.safe_load(open('${file}'))`,
        ])
        return { file, valid: checkResult.exitCode === 0 }
      }),
    { concurrency: 'unbounded' },
  )

  // Report all invalid files
  const invalid = results.filter((r) => !r.valid)
  for (const r of invalid) {
    yield* Console.error(`    Invalid YAML: ${r.file}`)
  }

  return invalid.length === 0
})

/**
 * Run config validation
 */
export const runConfigValidation = Effect.gen(function* () {
  yield* Console.log('\n📋 Config Validation')
  yield* Console.log('─'.repeat(50))

  const [jsonValid, yamlValid] = yield* Effect.all([validateJson, validateYaml], {
    concurrency: 'unbounded',
  })

  const success = jsonValid && yamlValid

  if (success) {
    yield* Console.log('✅ Config validation passed')
  } else {
    yield* Console.error('❌ Config validation failed')
  }

  return { success, jsonValid, yamlValid }
})
