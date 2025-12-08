/**
 * TemplateEngine Effect Layer
 *
 * Provides Handlebars template rendering as an Effect Layer.
 * Uses Handlebars for template syntax with Mustache-compatible placeholders.
 */
import { Context, Effect, Layer } from 'effect'
import Handlebars from 'handlebars'
import type { FileTree } from './file-system'

// =============================================================================
// Types
// =============================================================================

/**
 * Template data - arbitrary object passed to templates
 */
export type TemplateData = Record<string, unknown>

/**
 * TemplateEngine service interface (Port)
 */
export interface TemplateEngineService {
  readonly render: (template: string, data: TemplateData) => Effect.Effect<string, Error>
  readonly renderAll: (templates: FileTree, data: TemplateData) => Effect.Effect<FileTree, Error>
}

// =============================================================================
// Context Tag (Port Definition)
// =============================================================================

/**
 * TemplateEngine Context Tag - the Port that generators depend on
 */
export class TemplateEngine extends Context.Tag('TemplateEngine')<
  TemplateEngine,
  TemplateEngineService
>() {}

// =============================================================================
// Live Implementation (Adapter)
// =============================================================================

/**
 * Create the live TemplateEngine service implementation
 */
const makeTemplateEngineService = (): TemplateEngineService => ({
  render: (template: string, data: TemplateData) =>
    Effect.try({
      try: () => {
        const compiled = Handlebars.compile(template, { strict: false })
        return compiled(data)
      },
      catch: (e) => new Error(`Template rendering failed: ${e}`),
    }),

  renderAll: (templates: FileTree, data: TemplateData) =>
    Effect.forEach(
      Object.entries(templates),
      ([path, template]) =>
        Effect.try({
          try: () => {
            const compiled = Handlebars.compile(template, { strict: false })
            return [path, compiled(data)] as const
          },
          catch: (e) => new Error(`Template rendering failed for ${path}: ${e}`),
        }),
      { concurrency: 'unbounded' }
    ).pipe(Effect.map((entries) => Object.fromEntries(entries))),
})

/**
 * TemplateEngineLive - the live Layer providing the TemplateEngine service
 */
export const TemplateEngineLive = Layer.succeed(TemplateEngine, makeTemplateEngineService())

// =============================================================================
// Convenience Functions
// =============================================================================

/**
 * Render a single template - requires TemplateEngine in context
 */
export const renderTemplate = (
  template: string,
  data: TemplateData
): Effect.Effect<string, Error, TemplateEngine> =>
  Effect.flatMap(TemplateEngine, (engine) => engine.render(template, data))

/**
 * Render multiple templates (FileTree) - requires TemplateEngine in context
 */
export const renderTemplates = (
  templates: FileTree,
  data: TemplateData
): Effect.Effect<FileTree, Error, TemplateEngine> =>
  Effect.flatMap(TemplateEngine, (engine) => engine.renderAll(templates, data))
