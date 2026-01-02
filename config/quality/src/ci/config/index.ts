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
  let valid = true

  for (const file of files) {
    const checkResult = yield* runCommand('python3', ['-m', 'json.tool', file])
    if (checkResult.exitCode !== 0) {
      yield* Console.error(`    Invalid JSON: ${file}`)
      valid = false
    }
  }

  return valid
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
  let valid = true

  for (const file of files) {
    const checkResult = yield* runCommand('python3', [
      '-c',
      `import yaml; yaml.safe_load(open('${file}'))`,
    ])
    if (checkResult.exitCode !== 0) {
      yield* Console.error(`    Invalid YAML: ${file}`)
      valid = false
    }
  }

  return valid
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
