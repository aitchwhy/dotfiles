/**
 * Critic Mode Schema - Effect Schema SSOT
 *
 * Structured self-review behaviors for planning and execution phases.
 * Metacognitive protocols to catch common failure modes.
 */
import { Schema } from 'effect';

export const CriticPhaseSchema = Schema.Literal(
  'planning', // Before writing code
  'execution' // During code implementation
);
export type CriticPhase = typeof CriticPhaseSchema.Type;

export const CriticBehaviorSchema = Schema.Struct({
  id: Schema.String.pipe(Schema.pattern(/^[a-z0-9-]+$/)),
  phase: CriticPhaseSchema,
  title: Schema.String.pipe(Schema.maxLength(60)),
  trigger: Schema.String.pipe(Schema.maxLength(200)),
  action: Schema.String.pipe(Schema.maxLength(300)),
});
export type CriticBehavior = typeof CriticBehaviorSchema.Type;

export const CriticModeConfigSchema = Schema.Struct({
  enabled: Schema.Boolean,
  behaviors: Schema.Array(CriticBehaviorSchema),
});
export type CriticModeConfig = typeof CriticModeConfigSchema.Type;

export const decodeCriticBehavior = Schema.decodeUnknown(CriticBehaviorSchema);
export const decodeCriticModeConfig = Schema.decodeUnknown(CriticModeConfigSchema);
