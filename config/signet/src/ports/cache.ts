/**
 * Cache Port - Caching Service Interface
 *
 * Defines the contract for key-value caching operations.
 * Implemented by adapters like Redis.
 */
import { Context, type Effect, Schema } from 'effect';

// ============================================================================
// SCHEMAS
// ============================================================================

export const CacheOptions = Schema.Struct({
  ttlSeconds: Schema.optional(Schema.Number),
  namespace: Schema.optional(Schema.String),
});

export type CacheOptions = Schema.Schema.Type<typeof CacheOptions>;

// ============================================================================
// ERRORS
// ============================================================================

export class CacheError extends Schema.TaggedError<CacheError>()('CacheError', {
  code: Schema.Literal(
    'KEY_NOT_FOUND',
    'SERIALIZATION_ERROR',
    'CONNECTION_ERROR',
    'TIMEOUT',
    'INTERNAL_ERROR'
  ),
  message: Schema.String,
  key: Schema.optional(Schema.String),
}) {}

// ============================================================================
// PORT INTERFACE
// ============================================================================

export interface CacheService {
  readonly get: <T>(key: string) => Effect.Effect<T | null, CacheError>;

  readonly set: <T>(
    key: string,
    value: T,
    options?: CacheOptions
  ) => Effect.Effect<void, CacheError>;

  readonly delete: (key: string) => Effect.Effect<boolean, CacheError>;

  readonly exists: (key: string) => Effect.Effect<boolean, CacheError>;

  readonly getMany: <T>(keys: readonly string[]) => Effect.Effect<Map<string, T>, CacheError>;

  readonly setMany: <T>(
    entries: readonly [string, T][],
    options?: CacheOptions
  ) => Effect.Effect<void, CacheError>;

  readonly deleteMany: (keys: readonly string[]) => Effect.Effect<number, CacheError>;

  readonly clear: (pattern?: string) => Effect.Effect<number, CacheError>;
}

export class Cache extends Context.Tag('Cache')<Cache, CacheService>() {}
