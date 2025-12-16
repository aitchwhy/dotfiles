/**
 * Test Helpers for ProjectSpec
 *
 * Provides properly typed test fixtures that satisfy branded type constraints.
 */
import { Schema } from 'effect';
import { ProjectName, ProjectSpec } from '@/schema/project-spec';

/**
 * Creates a valid ProjectSpec for testing with proper branded types.
 * Uses Schema.decodeSync to ensure all branded types are properly constructed.
 */
export const makeSpec = (
  overrides: Partial<Schema.Schema.Encoded<typeof ProjectSpec>> = {}
): typeof ProjectSpec.Type =>
  Schema.decodeSync(ProjectSpec)({
    name: 'test-project',
    type: 'api',
    infra: { runtime: 'bun', database: 'turso' },
    observability: { processCompose: true, metrics: false, debugger: 'vscode' },
    ...overrides,
  });

/**
 * Creates a valid ProjectName for testing.
 */
export const makeProjectName = (name: string): typeof ProjectName.Type =>
  Schema.decodeSync(ProjectName)(name);
