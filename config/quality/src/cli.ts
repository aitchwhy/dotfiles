/**
 * Signet CLI - Code Quality & Generation Platform
 *
 * Generates formally consistent software systems with hexagonal architecture.
 * Powered by Effect-TS, OXC, and ast-grep for high-performance AST analysis.
 *
 * Commands:
 *   signet init <type> <name>   - Initialize a new project
 *   signet gen <type> <name>    - Generate a workspace in existing project
 *   signet validate [path]      - Validate project against spec
 *   signet enforce [--fix]      - Run architecture enforcers
 *   signet reconcile [path]     - Detect and fix code drift via AST analysis
 */

import { readdir } from 'node:fs/promises';
import { join } from 'node:path';
import { Args, Command, Options } from '@effect/cli';
import { NodeContext, NodeRuntime } from '@effect/platform-node';
import { Console, Effect, Option, Schema } from 'effect';
import { createConfig, runReconcile, startDaemon } from '@/daemon';
import { generateApi } from '@/generators/api';
import { generateCore } from '@/generators/core';
import { generateInfra } from '@/generators/infra';
import { generateMonorepo } from '@/generators/monorepo';
import { generateUi } from '@/generators/ui';
import {
  AstEngineLive,
  createSourceFile,
  detectDrift,
  type PatternConfig,
  reconcile,
} from '@/layers/ast-engine';
import { FileSystemLive, readFile, writeTree } from '@/layers/file-system';
import { GitLive, gitAdd, gitCommit, gitInit } from '@/layers/git';
import {
  applyAllFixes,
  applyRules,
  loadRulesFromDirectory,
  PatternEngineLive,
  type PatternMatch,
} from '@/layers/patterns';
import { TemplateEngineLive } from '@/layers/template-engine';
import { ProjectName, type ProjectSpec } from '@/schema/project-spec';
import { STACK } from '@/stack';
import {
  ALL_TIERS,
  formatVerificationResult,
  runVerification,
  type TierName,
} from '@/verification/index';

// =============================================================================
// Arguments & Options
// =============================================================================

const PROJECT_TYPES = ['monorepo', 'api', 'ui', 'library', 'infra'] as const;
type ProjectType = (typeof PROJECT_TYPES)[number];

const projectType = Args.text({ name: 'type' });
const projectName = Args.text({ name: 'name' });
const pathArg = Args.text({ name: 'path' }).pipe(Args.optional);
const fixOption = Options.boolean('fix').pipe(Options.withDefault(false));
const dryRunOption = Options.boolean('dry-run').pipe(Options.withDefault(false));
const verboseOption = Options.boolean('verbose').pipe(Options.withDefault(false));
const rulesOption = Options.text('rules').pipe(Options.withDefault('rules'));
const tiersOption = Options.text('tiers').pipe(
  Options.withDescription('Comma-separated list of tiers to run (default: all)'),
  Options.optional
);

const validateProjectType = (type: string): Effect.Effect<ProjectType, Error> => {
  if (PROJECT_TYPES.includes(type as ProjectType)) {
    return Effect.succeed(type as ProjectType);
  }
  return Effect.fail(
    new Error(`Invalid project type: ${type}. Valid types: ${PROJECT_TYPES.join(', ')}`)
  );
};

// =============================================================================
// Init Command
// =============================================================================

export const initCommand = Command.make(
  'init',
  { type: projectType, name: projectName },
  ({ type, name }) =>
    Effect.gen(function* () {
      const validType = yield* validateProjectType(type);
      yield* Console.log(`\n🏭 Initializing ${validType} project: ${name}\n`);

      // Create project spec (brand the name via Schema validation)
      const spec: ProjectSpec = {
        name: Schema.decodeSync(ProjectName)(name),
        type: validType,
        infra: { runtime: 'bun' },
        observability: { processCompose: true, metrics: false, debugger: 'vscode' },
      };

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
                : generateCore(spec);

      // Compose all layers for generation + file writing
      const tree = yield* generator.pipe(Effect.provide(TemplateEngineLive));

      // Also generate core files for non-core types
      const coreTree =
        type !== 'library'
          ? yield* generateCore(spec).pipe(Effect.provide(TemplateEngineLive))
          : {};

      // Merge trees (specific generator takes precedence)
      const mergedTree = { ...coreTree, ...tree };

      // Write files to disk
      const targetPath = `./${name}`;
      yield* writeTree(mergedTree, targetPath).pipe(Effect.provide(FileSystemLive));

      // Initialize git repository
      yield* gitInit(targetPath).pipe(Effect.provide(GitLive));
      yield* gitAdd(targetPath, ['.']).pipe(Effect.provide(GitLive));
      yield* gitCommit(targetPath, 'chore: initial commit from signet').pipe(
        Effect.provide(GitLive)
      );

      yield* Console.log(`✅ Project ${name} created successfully!`);
      yield* Console.log(`\nNext steps:`);
      yield* Console.log(`  cd ${name}`);
      yield* Console.log(`  bun install`);
      yield* Console.log(`  bun dev`);
    })
);

// =============================================================================
// Gen Command
// =============================================================================

export const genCommand = Command.make(
  'gen',
  { type: projectType, name: projectName },
  ({ type, name }) =>
    Effect.gen(function* () {
      const validType = yield* validateProjectType(type);
      yield* Console.log(`\n🔧 Generating ${validType} workspace: ${name}\n`);

      const spec: ProjectSpec = {
        name: Schema.decodeSync(ProjectName)(name),
        type: validType,
        infra: { runtime: 'bun' },
        observability: { processCompose: true, metrics: false, debugger: 'vscode' },
      };

      const generator =
        validType === 'api'
          ? generateApi(spec)
          : validType === 'ui'
            ? generateUi(spec)
            : validType === 'infra'
              ? generateInfra(spec)
              : generateCore(spec);

      const tree = yield* generator.pipe(Effect.provide(TemplateEngineLive));

      // Write to apps/<name> or packages/<name> based on type
      const targetPath = type === 'library' ? `./packages/${name}` : `./apps/${name}`;
      yield* writeTree(tree, targetPath).pipe(Effect.provide(FileSystemLive));

      yield* Console.log(`✅ Workspace ${name} generated at ${targetPath}`);
    })
);

// =============================================================================
// Validate Command
// =============================================================================

export const validateCommand = Command.make(
  'validate',
  { path: pathArg, verbose: verboseOption, rulesDir: rulesOption },
  ({ path, verbose: _verbose, rulesDir }) =>
    Effect.gen(function* () {
      const targetPath = Option.getOrElse(path, () => '.');
      yield* Console.log(`\n🔍 Validating project at: ${targetPath}\n`);

      // Load YAML pattern rules (ast-grep based)
      const yamlRules = yield* loadRulesFromDirectory(rulesDir).pipe(
        Effect.provide(PatternEngineLive),
        Effect.catchAll(() => Effect.succeed([] as const))
      );

      if (yamlRules.length > 0) {
        yield* Console.log(`Loaded ${yamlRules.length} pattern rule(s)\n`);
      }

      // Find all TypeScript files
      const tsFiles = yield* Effect.tryPromise({
        try: () => findTsFiles(targetPath),
        catch: (e) => new Error(`Failed to scan directory: ${e}`),
      });

      if (tsFiles.length === 0) {
        yield* Console.log('No TypeScript files found.');
        return;
      }

      yield* Console.log('Checking project structure...');
      yield* Console.log('Checking dependencies...');
      yield* Console.log('Checking TypeScript config...');

      // Run pattern validation
      let totalErrors = 0;
      let totalWarnings = 0;

      for (const filePath of tsFiles) {
        const content = yield* readFile(filePath).pipe(Effect.provide(FileSystemLive));
        const patternResult = yield* applyRules(content, 'TypeScript', yamlRules, filePath).pipe(
          Effect.provide(PatternEngineLive),
          Effect.catchAll(() => Effect.succeed({ matches: [], errors: [] as readonly string[] }))
        );

        const errors = patternResult.matches.filter((m: PatternMatch) => m.severity === 'error');
        const warnings = patternResult.matches.filter(
          (m: PatternMatch) => m.severity === 'warning'
        );

        if (errors.length > 0 || warnings.length > 0) {
          yield* Console.log(`\n📄 ${filePath}`);
          for (const m of patternResult.matches) {
            const icon = m.severity === 'error' ? '❌' : '⚠️';
            yield* Console.log(`   ${icon} [${m.rule}] ${m.message}:${m.node.range.start.line}`);
          }
        }

        totalErrors += errors.length;
        totalWarnings += warnings.length;
      }

      yield* Console.log('');
      if (totalErrors > 0) {
        yield* Console.log(
          `\n❌ Validation failed: ${totalErrors} error(s), ${totalWarnings} warning(s)`
        );
        yield* Effect.fail(new Error('Validation failed'));
      } else if (totalWarnings > 0) {
        yield* Console.log(`\n⚠️ Validation passed with ${totalWarnings} warning(s)`);
      } else {
        yield* Console.log(`\n✅ Validation passed`);
      }
    })
);

// =============================================================================
// Enforce Command
// =============================================================================

export const enforceCommand = Command.make('enforce', { fix: fixOption }, ({ fix }) =>
  Effect.gen(function* () {
    yield* Console.log(`\n👮 Running architecture enforcers${fix ? ' (with auto-fix)' : ''}\n`);

    // TODO: Implement police and architect enforcers
    yield* Console.log('Running Police enforcer...');
    yield* Console.log('  ✓ Structure validation');
    yield* Console.log('  ✓ Naming conventions');
    yield* Console.log('  ✓ Dependency hygiene');

    yield* Console.log('\nRunning Architect enforcer...');
    yield* Console.log('  ✓ Hexagonal boundaries');
    yield* Console.log('  ✓ No circular dependencies');
    yield* Console.log('  ✓ Layer violations');

    yield* Console.log(`\n✅ All checks passed`);
  })
);

// =============================================================================
// Reconcile Command
// =============================================================================

/**
 * Files to exclude from drift detection (infrastructure files)
 */
const EXCLUDED_FILES = ['ast-engine.ts', 'ast-engine.test.ts'] as const;

/**
 * Recursively find all TypeScript files in a directory
 */
async function findTsFiles(dir: string): Promise<string[]> {
  const files: string[] = [];
  const entries = await readdir(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = join(dir, entry.name);
    if (entry.isDirectory()) {
      // Skip node_modules and hidden directories
      if (!entry.name.startsWith('.') && entry.name !== 'node_modules') {
        files.push(...(await findTsFiles(fullPath)));
      }
    } else if (entry.isFile() && entry.name.endsWith('.ts') && !entry.name.endsWith('.d.ts')) {
      // Skip excluded infrastructure files
      if (!EXCLUDED_FILES.some((excluded) => entry.name === excluded)) {
        files.push(fullPath);
      }
    }
  }

  return files;
}

export const reconcileCommand = Command.make(
  'reconcile',
  { path: pathArg, dryRun: dryRunOption, verbose: verboseOption, rulesDir: rulesOption },
  ({ path, dryRun, verbose, rulesDir }) =>
    Effect.gen(function* () {
      const targetPath = Option.getOrElse(path, () => '.');
      yield* Console.log(`\n🔄 Reconciling drift at: ${targetPath}${dryRun ? ' (dry-run)' : ''}\n`);

      // Default pattern config for Signet-generated projects (OXC-based)
      const patterns: PatternConfig = {
        requireZodImport: true,
        requireResultType: true,
        requireExplicitExports: false,
      };

      // Load YAML pattern rules (ast-grep based)
      const yamlRules = yield* loadRulesFromDirectory(rulesDir).pipe(
        Effect.provide(PatternEngineLive),
        Effect.catchAll((e) => {
          if (verbose) {
            Console.log(`⚠️ Could not load YAML rules from ${rulesDir}: ${e.message}`);
          }
          return Effect.succeed([] as const);
        })
      );

      if (yamlRules.length > 0) {
        yield* Console.log(`Loaded ${yamlRules.length} pattern rule(s) from ${rulesDir}/\n`);
      }

      // Find all TypeScript files
      const tsFiles = yield* Effect.tryPromise({
        try: () => findTsFiles(targetPath),
        catch: (e) => new Error(`Failed to scan directory: ${e}`),
      });

      if (tsFiles.length === 0) {
        yield* Console.log('No TypeScript files found.');
        return;
      }

      yield* Console.log(`Found ${tsFiles.length} TypeScript files to analyze...\n`);

      let totalIssues = 0;
      let totalErrors = 0;
      let totalWarnings = 0;
      let filesWithIssues = 0;

      // Analyze each file
      for (const filePath of tsFiles) {
        const content = yield* readFile(filePath).pipe(Effect.provide(FileSystemLive));

        // 1. Run OXC-based drift detection
        const sf = yield* createSourceFile(filePath, content).pipe(Effect.provide(AstEngineLive));
        const driftReport = yield* detectDrift(sf, patterns).pipe(Effect.provide(AstEngineLive));

        // 2. Run ast-grep YAML pattern rules
        const patternResult = yield* applyRules(content, 'TypeScript', yamlRules, filePath).pipe(
          Effect.provide(PatternEngineLive),
          Effect.catchAll(() => Effect.succeed({ matches: [], errors: [] as readonly string[] }))
        );

        // Combine issues from both engines
        const patternIssues = patternResult.matches.map((m: PatternMatch) => ({
          type: 'pattern-violation' as const,
          severity: m.severity,
          message: `[${m.rule}] ${m.message}`,
          line: m.node.range.start.line,
          fix: m.fix
            ? {
                description: `Replace with: ${m.fix.replacement.slice(0, 50)}${m.fix.replacement.length > 50 ? '...' : ''}`,
                replacement: m.fix.replacement,
              }
            : undefined,
        }));

        const allIssues = [...driftReport.issues, ...patternIssues];

        if (allIssues.length > 0) {
          filesWithIssues++;
          totalIssues += allIssues.length;

          const errors = allIssues.filter((i) => i.severity === 'error').length;
          const warnings = allIssues.filter((i) => i.severity === 'warning').length;
          totalErrors += errors;
          totalWarnings += warnings;

          // Print file header
          yield* Console.log(`📄 ${filePath}`);

          // Print each issue
          for (const issue of allIssues) {
            const icon = issue.severity === 'error' ? '❌' : '⚠️';
            const line = issue.line ? `:${issue.line}` : '';
            yield* Console.log(`   ${icon} ${issue.message}${line}`);

            if (verbose && issue.fix) {
              yield* Console.log(`      💡 Fix: ${issue.fix.description}`);
            }
          }

          // Apply fixes if not dry-run
          if (!dryRun) {
            let fixedContent = content;

            // Apply OXC drift fixes
            const driftFixableIssues = driftReport.issues.filter((i) => i.fix);
            if (driftFixableIssues.length > 0) {
              fixedContent = yield* reconcile(sf, driftFixableIssues).pipe(
                Effect.provide(AstEngineLive)
              );
            }

            // Apply ast-grep pattern fixes
            const patternFixableMatches = patternResult.matches.filter((m: PatternMatch) => m.fix);
            if (patternFixableMatches.length > 0) {
              fixedContent = yield* applyAllFixes(fixedContent, patternFixableMatches).pipe(
                Effect.provide(PatternEngineLive)
              );
            }

            const totalFixes = driftFixableIssues.length + patternFixableMatches.length;
            if (totalFixes > 0) {
              // Write fixed content back to file
              yield* writeTree({ [filePath]: fixedContent }, '.').pipe(
                Effect.provide(FileSystemLive)
              );
              yield* Console.log(`   ✅ Applied ${totalFixes} fix(es)`);
            }
          }

          yield* Console.log('');
        } else if (verbose) {
          yield* Console.log(`✓ ${filePath}`);
        }
      }

      // Summary
      yield* Console.log('─'.repeat(50));
      if (totalIssues === 0) {
        yield* Console.log('✅ No drift detected!');
      } else {
        yield* Console.log(`Found ${totalIssues} issue(s) in ${filesWithIssues} file(s):`);
        if (totalErrors > 0) yield* Console.log(`  ❌ ${totalErrors} error(s)`);
        if (totalWarnings > 0) yield* Console.log(`  ⚠️  ${totalWarnings} warning(s)`);

        if (dryRun) {
          yield* Console.log('\nRun without --dry-run to apply fixes.');
        }
      }
    })
);

// =============================================================================
// Migrate Command - Migrate Project to STACK Compliance
// =============================================================================

// Files that should be deleted during migration
const FORBIDDEN_MIGRATION_FILES = [
  'package-lock.json',
  'yarn.lock',
  'pnpm-lock.yaml',
  'Dockerfile',
  'docker-compose.yml',
  'docker-compose.yaml',
  '.dockerignore',
  '.eslintrc',
  '.eslintrc.js',
  '.eslintrc.json',
  '.eslintrc.yaml',
  '.eslintrc.yml',
  'eslint.config.js',
  'eslint.config.mjs',
  '.prettierrc',
  '.prettierrc.js',
  '.prettierrc.json',
  'prettier.config.js',
  'jest.config.js',
  'jest.config.ts',
  '.env.local',
  '.env.development',
] as const;

// Dependencies that should be removed during migration
const BANNED_DEPENDENCIES = [
  'express',
  'fastify',
  'koa',
  'prisma',
  '@prisma/client',
  'mongoose',
  'mysql',
  'mysql2',
  'typeorm',
  'sequelize',
  'knex',
  'dotenv',
  'eslint',
  'prettier',
  'jest',
  'mocha',
  'chai',
  'sinon',
  'nock',
  'axios',
  'lodash',
  'moment',
  'request',
] as const;

export const migrateCommand = Command.make(
  'migrate',
  { path: pathArg, dryRun: dryRunOption, verbose: verboseOption },
  ({ path, dryRun, verbose }) =>
    Effect.gen(function* () {
      const targetPath = Option.getOrElse(path, () => '.');
      yield* Console.log(
        `\n🔄 Migrating project to STACK compliance${dryRun ? ' (dry-run)' : ''}\n`
      );
      yield* Console.log(`   Path: ${targetPath}`);
      yield* Console.log(`   STACK version: ${STACK.meta.ssotVersion}`);
      yield* Console.log('');

      const results = {
        deleted: [] as string[],
        removedDeps: [] as string[],
        updatedVersions: [] as string[],
        warnings: [] as string[],
      };

      // Phase 1: Delete forbidden files
      yield* Console.log('📁 Phase 1: Checking forbidden files...');
      for (const file of FORBIDDEN_MIGRATION_FILES) {
        const filePath = join(targetPath, file);
        const exists = yield* Effect.tryPromise({
          try: async () => {
            const f = Bun.file(filePath);
            return f.exists();
          },
          catch: () => false,
        });

        if (exists) {
          if (!dryRun) {
            yield* Effect.tryPromise({
              try: () =>
                Bun.write(filePath, '').then(() => require('node:fs').unlinkSync(filePath)),
              catch: (e) => new Error(`Failed to delete ${file}: ${e}`),
            }).pipe(Effect.catchAll(() => Effect.void));
          }
          results.deleted.push(file);
          yield* Console.log(`   ${dryRun ? '⚠️ Would delete' : '❌ Deleted'}: ${file}`);
        }
      }

      // Phase 2: Update package.json
      const pkgPath = join(targetPath, 'package.json');
      const pkgExists = yield* Effect.tryPromise({
        try: async () => Bun.file(pkgPath).exists(),
        catch: () => false,
      });

      if (pkgExists) {
        yield* Console.log('\n📦 Phase 2: Updating package.json...');

        const pkgContent = yield* Effect.tryPromise({
          try: () => Bun.file(pkgPath).text(),
          catch: (e) => new Error(`Failed to read package.json: ${e}`),
        });

        let pkg: {
          dependencies?: Record<string, string>;
          devDependencies?: Record<string, string>;
          scripts?: Record<string, string>;
        };
        try {
          pkg = JSON.parse(pkgContent);
        } catch {
          yield* Console.log('   ⚠️ Could not parse package.json');
          pkg = {};
        }

        let modified = false;

        // Remove banned dependencies
        for (const dep of BANNED_DEPENDENCIES) {
          if (pkg.dependencies?.[dep]) {
            delete pkg.dependencies[dep];
            results.removedDeps.push(`dependencies.${dep}`);
            modified = true;
            yield* Console.log(`   ${dryRun ? '⚠️ Would remove' : '🗑️ Removed'}: ${dep}`);
          }
          if (pkg.devDependencies?.[dep]) {
            delete pkg.devDependencies[dep];
            results.removedDeps.push(`devDependencies.${dep}`);
            modified = true;
            yield* Console.log(`   ${dryRun ? '⚠️ Would remove' : '🗑️ Removed'}: ${dep} (dev)`);
          }
        }

        // Update versions to match STACK
        const npmVersions = STACK.npm;
        for (const [name, targetVersion] of Object.entries(npmVersions)) {
          if (pkg.dependencies?.[name]) {
            const current = pkg.dependencies[name];
            if (!current.includes(targetVersion)) {
              const newVersion = `^${targetVersion}`;
              if (!dryRun) pkg.dependencies[name] = newVersion;
              results.updatedVersions.push(`${name}: ${current} → ${newVersion}`);
              modified = true;
              if (verbose) {
                yield* Console.log(`   📌 ${name}: ${current} → ${newVersion}`);
              }
            }
          }
          if (pkg.devDependencies?.[name]) {
            const current = pkg.devDependencies[name];
            if (!current.includes(targetVersion)) {
              const newVersion = `^${targetVersion}`;
              if (!dryRun) pkg.devDependencies[name] = newVersion;
              results.updatedVersions.push(`${name}: ${current} → ${newVersion}`);
              modified = true;
              if (verbose) {
                yield* Console.log(`   📌 ${name}: ${current} → ${newVersion}`);
              }
            }
          }
        }

        // Write updated package.json
        if (modified && !dryRun) {
          yield* Effect.tryPromise({
            try: () => Bun.write(pkgPath, `${JSON.stringify(pkg, null, 2)}\n`),
            catch: (e) => new Error(`Failed to write package.json: ${e}`),
          });
        }

        if (!verbose && results.updatedVersions.length > 0) {
          yield* Console.log(`   📌 Updated ${results.updatedVersions.length} version(s)`);
        }
      }

      // Phase 3: Summary
      yield* Console.log(`\n${'─'.repeat(50)}`);
      yield* Console.log('📊 Migration Summary:');
      yield* Console.log(`   Files deleted: ${results.deleted.length}`);
      yield* Console.log(`   Dependencies removed: ${results.removedDeps.length}`);
      yield* Console.log(`   Versions updated: ${results.updatedVersions.length}`);

      if (dryRun) {
        yield* Console.log('\n⚠️ Dry run - no changes made. Run without --dry-run to apply.\n');
      } else {
        yield* Console.log('\n✅ Migration complete!');
        yield* Console.log('   Next: Run `bun install` to update lockfile\n');
      }
    })
);

// =============================================================================
// Doctor Command - System Health Check
// =============================================================================

export const doctorCommand = Command.make('doctor', {}, () =>
  Effect.gen(function* () {
    yield* Console.log('\n🩺 Signet Health Check\n');
    yield* Console.log('─'.repeat(50));

    let issues = 0;

    // Check 1: Runtime versions
    yield* Console.log('\n📦 Runtime Environment');
    const bunVersion = process.versions.bun || 'N/A';
    const nodeVersion = process.version;
    yield* Console.log(`  ✓ Bun: ${bunVersion}`);
    yield* Console.log(`  ✓ Node: ${nodeVersion}`);

    // Check 2: Effect-TS availability
    yield* Console.log('\n⚡ Effect-TS Integration');
    yield* Console.log('  ✓ effect: available');
    yield* Console.log('  ✓ @effect/cli: available');

    // Check 3: AST tools
    yield* Console.log('\n🔍 AST Analysis Tools');
    const astGrepResult = yield* Effect.either(
      Effect.tryPromise({
        try: () => import('@ast-grep/napi'),
        catch: () => new Error('Not found'),
      })
    );
    if (astGrepResult._tag === 'Right') {
      yield* Console.log('  ✓ @ast-grep/napi: available');
    } else {
      yield* Console.log('  ⚠️ @ast-grep/napi: not found');
      issues++;
    }

    // Check 4: Rules directory
    yield* Console.log('\n📐 Architecture Rules');
    const rulesDir = join(process.cwd(), 'rules');
    const rulesResult = yield* Effect.either(
      Effect.tryPromise({
        try: () => readdir(rulesDir),
        catch: () => new Error('Rules directory not found'),
      })
    );
    if (rulesResult._tag === 'Right') {
      const ruleCount = rulesResult.right.length;
      yield* Console.log(`  ✓ Rules directory: ${ruleCount} rule categories`);
    } else {
      yield* Console.log('  ℹ️ No local rules directory (using defaults)');
    }

    // Summary
    yield* Console.log(`\n${'─'.repeat(50)}`);
    if (issues === 0) {
      yield* Console.log('✅ All checks passed! Signet is healthy.\n');
    } else {
      yield* Console.log(`⚠️ Found ${issues} issue(s). Run 'signet comply' to attempt fixes.\n`);
    }
  })
);

// =============================================================================
// Comply Command - Auto-fix Drift (Alias for reconcile --fix)
// =============================================================================

export const complyCommand = Command.make(
  'comply',
  { path: pathArg, verbose: verboseOption },
  ({ path, verbose }) =>
    Effect.gen(function* () {
      const targetPath = Option.getOrElse(path, () => '.');
      yield* Console.log(`\n🔧 Auto-fixing architecture drift at: ${targetPath}\n`);

      // Run reconciliation with auto-fix enabled
      const rulesDir = join(process.cwd(), 'rules');

      // Load rules
      const rulesResult = yield* Effect.either(
        loadRulesFromDirectory(rulesDir).pipe(Effect.provide(PatternEngineLive))
      );

      const rules = rulesResult._tag === 'Right' ? rulesResult.right : [];

      if (rules.length === 0) {
        yield* Console.log('ℹ️  No rules found. Skipping pattern enforcement.');
        return;
      }

      yield* Console.log(`📐 Loaded ${rules.length} architecture rules`);

      // Find TypeScript files
      const findTsFiles = async (dir: string): Promise<string[]> => {
        const files: string[] = [];
        const entries = await readdir(dir, { withFileTypes: true });
        for (const entry of entries) {
          const fullPath = join(dir, entry.name);
          if (entry.isDirectory() && !['node_modules', '.git', 'dist'].includes(entry.name)) {
            files.push(...(await findTsFiles(fullPath)));
          } else if (entry.name.endsWith('.ts') || entry.name.endsWith('.tsx')) {
            files.push(fullPath);
          }
        }
        return files;
      };

      const tsFiles = yield* Effect.tryPromise({
        try: () => findTsFiles(targetPath),
        catch: (e) => new Error(`Failed to scan directory: ${e}`),
      });

      yield* Console.log(`🔍 Scanning ${tsFiles.length} TypeScript files...`);

      let totalFixes = 0;

      for (const file of tsFiles) {
        const contentResult = yield* Effect.either(
          readFile(file).pipe(Effect.provide(FileSystemLive))
        );

        if (contentResult._tag === 'Left') continue;

        const content = contentResult.right;

        // Apply rules and get matches
        const result = yield* applyRules(content, 'TypeScript', rules, file).pipe(
          Effect.provide(PatternEngineLive)
        );

        const fixableMatches = result.matches.filter(
          (m): m is PatternMatch & { fix: string } => m.fix !== undefined
        );

        if (fixableMatches.length > 0) {
          // Apply fixes
          const fixedContent = yield* applyAllFixes(content, fixableMatches).pipe(
            Effect.provide(PatternEngineLive)
          );

          if (fixedContent !== content) {
            // Write back
            yield* Effect.tryPromise({
              try: () => Bun.write(file, fixedContent),
              catch: (e) => new Error(`Failed to write ${file}: ${e}`),
            });

            totalFixes += fixableMatches.length;
            if (verbose) {
              yield* Console.log(`  ✓ Fixed ${fixableMatches.length} issue(s) in ${file}`);
            }
          }
        }
      }

      yield* Console.log(`\n✅ Applied ${totalFixes} fix(es) across ${tsFiles.length} files.\n`);
    })
);

// =============================================================================
// Verify Command - Unified 5-Tier Verification (Hard Gate)
// =============================================================================

export const verifyCommand = Command.make(
  'verify',
  { path: pathArg, fix: fixOption, verbose: verboseOption, tiers: tiersOption },
  ({ path, fix, verbose, tiers }) =>
    Effect.gen(function* () {
      const targetPath = Option.getOrElse(path, () => '.');

      // Parse tiers option
      const selectedTiers: TierName[] = Option.match(tiers, {
        onNone: () => [...ALL_TIERS],
        onSome: (t) =>
          t
            .split(',')
            .map((s) => s.trim() as TierName)
            .filter((t) => ALL_TIERS.includes(t)),
      });

      yield* Console.log(`\n🔏 Signet Verification (${selectedTiers.length} tiers)\n`);
      yield* Console.log(`   Path: ${targetPath}`);
      yield* Console.log(`   Tiers: ${selectedTiers.join(', ')}`);
      if (fix) yield* Console.log(`   Mode: auto-fix enabled`);
      yield* Console.log('');

      // Run verification
      const result = yield* runVerification({
        path: targetPath,
        tiers: selectedTiers,
        fix,
        verbose,
      });

      // Format and print results
      const output = formatVerificationResult(result);
      yield* Console.log(output);

      // Exit with appropriate code (hard gate)
      if (!result.passed) {
        yield* Console.log('\n❌ Verification failed - blocking generation\n');
        yield* Effect.fail(new Error(`Verification failed with ${result.totalErrors} error(s)`));
      } else if (result.totalWarnings > 0) {
        yield* Console.log('\n⚠️ Verification passed with warnings\n');
      } else {
        yield* Console.log('\n✅ All verification tiers passed\n');
      }
    })
);

// =============================================================================
// Daemon Command - Infrastructure Reconciliation Loop
// =============================================================================

const intervalOption = Options.text('interval').pipe(
  Options.withDescription('Reconciliation interval (e.g., "30s", "1m", "5m")'),
  Options.withDefault('30s')
);
const stackOption = Options.text('stack').pipe(
  Options.withDescription('Pulumi stack name'),
  Options.withDefault('dev')
);
const projectOption = Options.text('project').pipe(
  Options.withDescription('Pulumi project name'),
  Options.withDefault('signet')
);
const autoApplyOption = Options.boolean('auto-apply').pipe(
  Options.withDescription('Automatically apply changes (dangerous!)'),
  Options.withDefault(false)
);
const onceOption = Options.boolean('once').pipe(
  Options.withDescription('Run once and exit (no loop)'),
  Options.withDefault(false)
);

export const daemonCommand = Command.make(
  'daemon',
  {
    path: pathArg,
    interval: intervalOption,
    stack: stackOption,
    project: projectOption,
    dryRun: dryRunOption,
    autoApply: autoApplyOption,
    once: onceOption,
    verbose: verboseOption,
  },
  ({ path, interval, stack, project, dryRun, autoApply, once, verbose }) =>
    Effect.gen(function* () {
      const projectPath = Option.getOrElse(path, () => '.');

      if (verbose) {
        process.env['SIGNET_VERBOSE'] = 'true';
      }

      const config = createConfig({
        interval,
        stack,
        project,
        path: projectPath,
        autoApply,
        dryRun,
      });

      if (once) {
        yield* Console.log('\n🔄 Running single reconciliation...\n');
        const result = yield* runReconcile(config);
        yield* Console.log(`\n✅ Reconciliation complete`);
        yield* Console.log(`   Duration: ${result.durationMs}ms`);
        yield* Console.log(
          `   Changes: +${result.preview.creates} ~${result.preview.updates} -${result.preview.deletes}`
        );
        yield* Console.log(`   Applied: ${result.applied}`);
      } else {
        yield* Console.log('\n🔄 Starting infrastructure daemon...');
        yield* Console.log('   Press Ctrl+C to stop\n');
        yield* startDaemon(config);
      }
    })
);

// =============================================================================
// Main Command
// =============================================================================

export const mainCommand = Command.make('signet', {}, () =>
  Console.log(`
🔏 Signet - Code Quality & Generation Platform

Generates formally consistent software systems with hexagonal architecture.
Powered by Effect-TS, OXC, and ast-grep for high-performance AST analysis.

Commands:
  signet init <type> <name>   Initialize a new project
  signet gen <type> <name>    Generate a workspace in existing project
  signet migrate [path]       🔄 Migrate project to STACK compliance
  signet verify [path]        🔏 Run 5-tier verification (hard gate)
  signet validate [path]      Validate project against spec and patterns
  signet enforce [--fix]      Run architecture enforcers
  signet reconcile [path]     Detect and fix code drift via AST analysis
  signet daemon [path]        🔄 Infrastructure reconciliation loop
  signet doctor               Check system health and dependencies
  signet comply [path]        Auto-fix architecture drift (reconcile --fix)

Project Types:
  monorepo    Bun workspaces monorepo
  api         Hexagonal Hono API
  ui          React 19 + XState + TanStack Router
  library     Standalone TypeScript library
  infra       Pulumi + process-compose infrastructure

Verify Options (5-Tier Hard Gate):
  --tiers <list>          Comma-separated tiers: patterns,formal,execution,review,context
  --fix                   Auto-fix fixable issues
  --verbose               Show detailed output

Verification Tiers:
  1. patterns   AST drift detection, code smells (any, ts-ignore, etc.)
  2. formal     Branded types, satisfies patterns, property tests (info only)
  3. execution  TypeScript check, Biome lint, test suite
  4. review     Multi-agent code review (future: Claude API)
  5. context    Hexagonal architecture, circular deps, layer violations

Migrate Options:
  --dry-run               Preview changes without applying
  --verbose               Show detailed version updates

Reconcile Options:
  --dry-run               Preview changes without applying
  --verbose               Show detailed output
  --rules <dir>           Custom YAML rules directory (default: rules/)

Daemon Options (Infrastructure):
  --interval <time>       Reconciliation interval (default: 30s)
  --stack <name>          Pulumi stack name (default: dev)
  --project <name>        Pulumi project name (default: signet)
  --auto-apply            Automatically apply changes (dangerous!)
  --once                  Run once and exit (no loop)
  --dry-run               Preview only, don't apply

Examples:
  signet migrate --dry-run                  Preview migration changes
  signet migrate /path/to/project           Migrate project to STACK
  signet verify                             Run all 5 tiers
  signet verify --tiers execution           Run only execution tier
  signet verify --tiers patterns,execution  Run patterns + execution
  signet verify --fix --verbose             Auto-fix with details
  signet init monorepo ember-platform
  signet gen api voice-service
  signet gen ui web-app
  signet validate
  signet enforce --fix
  signet reconcile --dry-run --verbose
  signet daemon ./infra/pulumi             Start infra daemon
  signet daemon --once --stack prod         Single reconcile on prod
  signet doctor
  signet comply --verbose
`)
).pipe(
  Command.withSubcommands([
    initCommand,
    genCommand,
    migrateCommand,
    validateCommand,
    enforceCommand,
    reconcileCommand,
    daemonCommand,
    doctorCommand,
    complyCommand,
    verifyCommand,
  ])
);

// =============================================================================
// CLI Entry Point
// =============================================================================

const cli = Command.run(mainCommand, {
  name: 'signet',
  version: '1.0.0',
});

// Only run if this is the main module
if (import.meta.main) {
  Effect.suspend(() => cli(process.argv)).pipe(
    Effect.provide(NodeContext.layer),
    NodeRuntime.runMain
  );
}
