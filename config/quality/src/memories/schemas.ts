/**
 * Memory Schema - Effect Schema SSOT
 *
 * Flat list of engineering patterns. No domains, no modules.
 * Staff-to-Principal level craft knowledge.
 */
import { Schema } from 'effect';

export const MemoryCategorySchema = Schema.Literal(
  'principle', // Guiding philosophies (highest priority)
  'constraint', // Hard rules that MUST be followed
  'pattern', // Reusable solutions
  'gotcha' // Pitfalls to avoid
);
export type MemoryCategory = typeof MemoryCategorySchema.Type;

export const MemorySchema = Schema.Struct({
  id: Schema.String.pipe(Schema.pattern(/^[a-z0-9-]+$/)),
  category: MemoryCategorySchema,
  title: Schema.String.pipe(Schema.maxLength(80)),
  content: Schema.String.pipe(Schema.maxLength(500)),
  verified: Schema.optional(Schema.String.pipe(Schema.pattern(/^\d{4}-\d{2}-\d{2}$/))),
});
export type Memory = typeof MemorySchema.Type;

export const decodeMemory = Schema.decodeUnknown(MemorySchema);
