/**
 * Tier 5: Codebase Context
 *
 * Architecture boundary validation:
 * - Hexagonal architecture checks (ports/adapters)
 * - Circular dependency detection
 * - Layer violation checks
 */
import { Effect } from 'effect'
import { readdir, readFile } from 'node:fs/promises'
import { join, extname, relative, dirname } from 'node:path'
import type { TierResult, VerificationOptions } from '../index.js'

// =============================================================================
// Types
// =============================================================================

type ImportInfo = {
  readonly file: string
  readonly imports: readonly string[]
}

type ArchViolation = {
  readonly type: 'layer' | 'circular' | 'boundary'
  readonly message: string
  readonly file: string
}

// =============================================================================
// Layer Definitions (Hexagonal Architecture)
// =============================================================================

/**
 * Layer order from outside to inside
 * Lower index = outer layer, can import from higher index layers
 */
const LAYER_ORDER = ['routes', 'middleware', 'app', 'ports', 'adapters', 'lib', 'schema', 'stack'] as const
type Layer = (typeof LAYER_ORDER)[number]

const getLayer = (filePath: string): Layer | null => {
  for (const layer of LAYER_ORDER) {
    if (filePath.includes(`/${layer}/`) || filePath.includes(`\\${layer}\\`)) {
      return layer
    }
  }
  return null
}

const getLayerIndex = (layer: Layer): number => LAYER_ORDER.indexOf(layer)

// =============================================================================
// Helpers
// =============================================================================

/**
 * Extract import paths from TypeScript source
 */
const extractImports = (content: string): string[] => {
  const imports: string[] = []

  // Match: import ... from '...' or import ... from "..."
  const importRegex = /import\s+(?:[\w\s{},*]+\s+from\s+)?['"]([^'"]+)['"]/g
  let match: RegExpExecArray | null

  while ((match = importRegex.exec(content)) !== null) {
    const importPath = match[1]
    if (importPath) imports.push(importPath)
  }

  // Match: require('...')
  const requireRegex = /require\s*\(\s*['"]([^'"]+)['"]\s*\)/g
  while ((match = requireRegex.exec(content)) !== null) {
    const importPath = match[1]
    if (importPath) imports.push(importPath)
  }

  return imports
}

/**
 * Check if import is a relative local import
 */
const isRelativeImport = (importPath: string): boolean =>
  importPath.startsWith('./') || importPath.startsWith('../')

/**
 * Resolve relative import to layer
 */
const resolveImportToLayer = (fromFile: string, importPath: string, _basePath: string): Layer | null => {
  if (!isRelativeImport(importPath)) {
    return null // External package
  }

  // Resolve relative path
  const fromDir = dirname(fromFile)
  const resolvedPath = join(fromDir, importPath)

  return getLayer(resolvedPath)
}

/**
 * Find TypeScript files recursively
 */
const findTsFiles = async (dir: string): Promise<string[]> => {
  const files: string[] = []

  try {
    const entries = await readdir(dir, { withFileTypes: true })

    for (const entry of entries) {
      const name = entry.name
      const fullPath = join(dir, name)

      if (name.startsWith('.') || name === 'node_modules') {
        continue
      }

      if (entry.isDirectory()) {
        files.push(...(await findTsFiles(fullPath)))
      } else {
        const ext = extname(name)
        if (['.ts', '.tsx'].includes(ext) && !name.includes('.test.') && !name.includes('.spec.')) {
          files.push(fullPath)
        }
      }
    }
  } catch {
    // Directory doesn't exist
  }

  return files
}

/**
 * Build import graph
 */
const buildImportGraph = async (basePath: string): Promise<ImportInfo[]> => {
  const srcPath = join(basePath, 'src')
  const files = await findTsFiles(srcPath)
  const graph: ImportInfo[] = []

  for (const file of files) {
    try {
      const content = await readFile(file, 'utf-8')
      const imports = extractImports(content)
      graph.push({
        file: relative(basePath, file),
        imports,
      })
    } catch {
      // Skip unreadable files
    }
  }

  return graph
}

/**
 * Check for layer violations
 */
const checkLayerViolations = (graph: ImportInfo[], basePath: string): ArchViolation[] => {
  const violations: ArchViolation[] = []

  for (const { file, imports } of graph) {
    const fromLayer = getLayer(file)
    if (!fromLayer) continue

    const fromIndex = getLayerIndex(fromLayer)

    for (const importPath of imports) {
      const toLayer = resolveImportToLayer(file, importPath, basePath)
      if (!toLayer) continue

      const toIndex = getLayerIndex(toLayer)

      // Outer layers should not import from inner layers (except lib/schema/stack)
      // Special case: ports should not import adapters (dependency inversion)
      if (fromLayer === 'ports' && toLayer === 'adapters') {
        violations.push({
          type: 'boundary',
          message: `Ports cannot import adapters (dependency inversion violation)`,
          file,
        })
      }

      // General layer check: can only import from same or outer layers
      if (fromIndex < toIndex && !['lib', 'schema', 'stack'].includes(toLayer)) {
        violations.push({
          type: 'layer',
          message: `Layer violation: ${fromLayer} importing from ${toLayer}`,
          file,
        })
      }
    }
  }

  return violations
}

/**
 * Detect circular dependencies (simplified DFS)
 */
const detectCircularDeps = (graph: ImportInfo[]): ArchViolation[] => {
  const violations: ArchViolation[] = []
  const fileToImports = new Map<string, string[]>()

  // Build adjacency map
  for (const { file, imports } of graph) {
    const relativeImports = imports
      .filter(isRelativeImport)
      .map((imp) => {
        // Normalize import path
        const normalized = imp.replace(/\.js$/, '').replace(/\/index$/, '')
        return normalized
      })
    fileToImports.set(file, relativeImports)
  }

  // Simple cycle detection (limited depth)
  const visited = new Set<string>()
  const stack = new Set<string>()

  const dfs = (file: string, path: string[]): boolean => {
    if (stack.has(file)) {
      violations.push({
        type: 'circular',
        message: `Circular dependency: ${[...path, file].join(' -> ')}`,
        file: path[0] ?? file,
      })
      return true
    }

    if (visited.has(file)) return false
    visited.add(file)
    stack.add(file)

    const imports = fileToImports.get(file) ?? []
    for (const imp of imports) {
      // Try to find matching file in graph
      const candidates = Array.from(fileToImports.keys()).filter(
        (f) => f.includes(imp) || imp.includes(f.replace(/\.ts$/, ''))
      )

      for (const candidate of candidates) {
        if (dfs(candidate, [...path, file])) {
          // Already found a cycle, stop early
          if (violations.length >= 5) {
            stack.delete(file)
            return true
          }
        }
      }
    }

    stack.delete(file)
    return false
  }

  for (const file of fileToImports.keys()) {
    if (!visited.has(file)) {
      dfs(file, [])
    }
    if (violations.length >= 5) break // Limit violations
  }

  return violations
}

// =============================================================================
// Tier Implementation
// =============================================================================

/**
 * Run Tier 5: Codebase Context
 */
export const runContextTier = (opts: VerificationOptions): Effect.Effect<TierResult, Error> =>
  Effect.gen(function* () {
    const startTime = Date.now()
    const details: string[] = []
    let totalErrors = 0
    let totalWarnings = 0

    // Build import graph
    const graph = yield* Effect.tryPromise({
      try: () => buildImportGraph(opts.path),
      catch: () => new Error('Failed to build import graph'),
    }).pipe(Effect.catchAll(() => Effect.succeed([] as ImportInfo[])))

    if (graph.length === 0) {
      details.push('No source files found for architecture analysis')
      return {
        tier: 'context' as const,
        passed: true,
        errors: 0,
        warnings: 0,
        details,
        duration: Date.now() - startTime,
      }
    }

    details.push(`Analyzing ${graph.length} files for architecture violations...`)

    // Check layer violations
    const layerViolations = checkLayerViolations(graph, opts.path)
    totalErrors += layerViolations.filter((v) => v.type === 'boundary').length
    totalWarnings += layerViolations.filter((v) => v.type === 'layer').length

    for (const v of layerViolations.slice(0, 5)) {
      details.push(`${v.file}: ${v.message}`)
    }

    // Check circular dependencies
    const circularViolations = detectCircularDeps(graph)
    totalWarnings += circularViolations.length

    for (const v of circularViolations.slice(0, 3)) {
      details.push(`Circular: ${v.message}`)
    }

    if (layerViolations.length === 0 && circularViolations.length === 0) {
      details.push('Architecture checks passed')
    }

    return {
      tier: 'context' as const,
      passed: totalErrors === 0,
      errors: totalErrors,
      warnings: totalWarnings,
      details,
      duration: Date.now() - startTime,
    }
  })
