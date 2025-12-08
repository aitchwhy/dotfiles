/**
 * Build Script
 *
 * Generates SKILL.md and .mdc files from TypeScript definitions.
 * Entry point: `bun run src/build.ts`
 */
import { mkdir, readdir, writeFile } from 'node:fs/promises'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { generateSkillMarkdown } from '@/lib/markdown'
import { generateCursorRuleMarkdown } from '@/lib/mdc'
import { Err, Ok, type Result } from '@/lib/result'
import type { CursorRule, SystemSkill } from '@/schema'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

/**
 * Configuration for the build process
 */
export interface BuildConfig {
  readonly outputDir: string
  readonly dryRun: boolean
}

/**
 * Result of building skills
 */
export interface BuildResult {
  readonly written: readonly string[]
  readonly skipped: readonly string[]
  readonly errors: readonly string[]
}

/**
 * Default output directories (relative to dotfiles root)
 */
const DEFAULT_SKILLS_OUTPUT_DIR = join(__dirname, '../../claude-code/skills')
const DEFAULT_RULES_OUTPUT_DIR = join(__dirname, '../../../.cursor/rules')

/**
 * Load all skill definitions from the definitions directory
 */
export async function loadSkillDefinitions(): Promise<SystemSkill[]> {
  const definitionsDir = join(__dirname, 'definitions/skills')
  const entries = await readdir(definitionsDir, { withFileTypes: true })

  const skills: SystemSkill[] = []

  for (const entry of entries) {
    if (entry.isFile() && entry.name.endsWith('.ts')) {
      const modulePath = join(definitionsDir, entry.name)
      const module = await import(modulePath)

      // Find exported skill (convention: {name}Skill export)
      for (const exportName of Object.keys(module)) {
        if (exportName.endsWith('Skill')) {
          skills.push(module[exportName] as SystemSkill)
        }
      }
    }
  }

  return skills
}

/**
 * Load all cursor rule definitions from the definitions directory
 */
export async function loadCursorRuleDefinitions(): Promise<CursorRule[]> {
  const definitionsDir = join(__dirname, 'definitions/cursor-rules')
  const entries = await readdir(definitionsDir, { withFileTypes: true })

  const rules: CursorRule[] = []

  for (const entry of entries) {
    if (entry.isFile() && entry.name.endsWith('.ts')) {
      const modulePath = join(definitionsDir, entry.name)
      const module = await import(modulePath)

      // Find exported rule (convention: {name}Rule export)
      for (const exportName of Object.keys(module)) {
        if (exportName.endsWith('Rule')) {
          rules.push(module[exportName] as CursorRule)
        }
      }
    }
  }

  return rules
}

/**
 * Build all skills to SKILL.md files
 */
export async function buildSkills(
  config: Partial<BuildConfig> = {}
): Promise<Result<BuildResult, Error>> {
  const { outputDir = DEFAULT_SKILLS_OUTPUT_DIR, dryRun = false } = config

  const written: string[] = []
  const skipped: string[] = []
  const errors: string[] = []

  try {
    const skills = await loadSkillDefinitions()

    for (const skill of skills) {
      const skillDir = join(outputDir, skill.name)
      const skillPath = join(skillDir, 'SKILL.md')

      if (dryRun) {
        skipped.push(skill.name)
        console.log(`[dry-run] Would write: ${skillPath}`)
        continue
      }

      try {
        // Create directory if it doesn't exist
        await mkdir(skillDir, { recursive: true })

        // Generate and write markdown
        const markdown = generateSkillMarkdown(skill)
        await writeFile(skillPath, markdown, 'utf-8')

        written.push(skill.name)
        console.log(`[write] ${skillPath}`)
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err)
        errors.push(`${skill.name}: ${message}`)
        console.error(`[error] ${skill.name}: ${message}`)
      }
    }

    return Ok({ written, skipped, errors })
  } catch (err) {
    return Err(err instanceof Error ? err : new Error(String(err)))
  }
}

/**
 * Build all cursor rules to .mdc files
 */
export async function buildCursorRules(
  config: Partial<BuildConfig> = {}
): Promise<Result<BuildResult, Error>> {
  const { outputDir = DEFAULT_RULES_OUTPUT_DIR, dryRun = false } = config

  const written: string[] = []
  const skipped: string[] = []
  const errors: string[] = []

  try {
    const rules = await loadCursorRuleDefinitions()

    // Ensure output directory exists
    if (!dryRun) {
      await mkdir(outputDir, { recursive: true })
    }

    for (const rule of rules) {
      // Convert kebab-case to snake_case for filename (matches original)
      const filename = `${rule.name.replace(/-/g, '_')}.mdc`
      const rulePath = join(outputDir, filename)

      if (dryRun) {
        skipped.push(rule.name)
        console.log(`[dry-run] Would write: ${rulePath}`)
        continue
      }

      try {
        // Generate and write markdown
        const markdown = generateCursorRuleMarkdown(rule)
        await writeFile(rulePath, markdown, 'utf-8')

        written.push(rule.name)
        console.log(`[write] ${rulePath}`)
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err)
        errors.push(`${rule.name}: ${message}`)
        console.error(`[error] ${rule.name}: ${message}`)
      }
    }

    return Ok({ written, skipped, errors })
  } catch (err) {
    return Err(err instanceof Error ? err : new Error(String(err)))
  }
}

/**
 * CLI entry point
 */
async function main(): Promise<void> {
  const args = process.argv.slice(2)
  const dryRun = args.includes('--dry-run')
  const skillsOnly = args.includes('--skills-only')
  const rulesOnly = args.includes('--rules-only')

  let totalWritten = 0
  let totalSkipped = 0
  let totalErrors = 0

  // Build skills (unless --rules-only)
  if (!rulesOnly) {
    console.log('Building skills...')
    console.log(`  Output: ${DEFAULT_SKILLS_OUTPUT_DIR}`)
    console.log(`  Dry run: ${dryRun}`)
    console.log('')

    const skillsResult = await buildSkills({ dryRun })

    if (!skillsResult.ok) {
      console.error('Skills build failed:', skillsResult.error.message)
      process.exit(1)
    }

    totalWritten += skillsResult.data.written.length
    totalSkipped += skillsResult.data.skipped.length
    totalErrors += skillsResult.data.errors.length

    console.log('')
    console.log(`Skills: ${skillsResult.data.written.length} written`)
  }

  // Build cursor rules (unless --skills-only)
  if (!skillsOnly) {
    console.log('')
    console.log('Building cursor rules...')
    console.log(`  Output: ${DEFAULT_RULES_OUTPUT_DIR}`)
    console.log(`  Dry run: ${dryRun}`)
    console.log('')

    const rulesResult = await buildCursorRules({ dryRun })

    if (!rulesResult.ok) {
      console.error('Cursor rules build failed:', rulesResult.error.message)
      process.exit(1)
    }

    totalWritten += rulesResult.data.written.length
    totalSkipped += rulesResult.data.skipped.length
    totalErrors += rulesResult.data.errors.length

    console.log('')
    console.log(`Cursor rules: ${rulesResult.data.written.length} written`)
  }

  // Summary
  console.log('')
  console.log('=== Build Summary ===')
  console.log(`Total Written: ${totalWritten}`)
  console.log(`Total Skipped: ${totalSkipped}`)
  console.log(`Total Errors: ${totalErrors}`)

  if (totalErrors > 0) {
    process.exit(1)
  }
}

// Run if executed directly
if (import.meta.main) {
  main()
}
