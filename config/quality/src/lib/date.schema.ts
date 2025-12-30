/**
 * Date Schema - Parse at Boundary
 *
 * Provides Effect-compatible date operations:
 * - Clock for current time (injectable/testable)
 * - Schema transforms for parsing stored dates
 *
 * This module is the ONLY place where Date construction is allowed,
 * as it represents the boundary between external data and domain types.
 * Named .schema.ts to indicate parse-at-boundary semantics.
 */

import { Clock, Effect, Schema } from 'effect'

// =============================================================================
// Schema Transforms (Parse at Boundary)
// =============================================================================

/**
 * Transform ISO date string to Unix timestamp (milliseconds)
 * Used for parsing stored dates from database/files
 */
export const DateStringToMs = Schema.transform(Schema.String, Schema.Number, {
  strict: true,
  decode: (iso) => new Date(iso).getTime(),
  encode: (ms) => new Date(ms).toISOString(),
})

/**
 * Transform optional date string to timestamp, with 0 as default
 */
export const OptionalDateStringToMs = Schema.transform(
  Schema.NullOr(Schema.String),
  Schema.Number,
  {
    strict: true,
    decode: (iso) => (iso ? new Date(iso).getTime() : 0),
    encode: (ms) => (ms > 0 ? new Date(ms).toISOString() : null),
  },
)

// =============================================================================
// Pure Utilities (No Effect needed)
// =============================================================================

/**
 * Parse a date string to milliseconds
 * For use at parse boundaries where Schema is overkill
 */
export const parseIsoToMs = (iso: string | null | undefined): number =>
  iso ? new Date(iso).getTime() : 0

/**
 * Format milliseconds to ISO string
 */
export const formatMsToIso = (ms: number): string => new Date(ms).toISOString()

// =============================================================================
// Effect-based Time Operations
// =============================================================================

/**
 * Get current time in milliseconds using Clock service
 * This is injectable and testable
 */
export const currentTimeMs: Effect.Effect<number> = Clock.currentTimeMillis

/**
 * Get current time as ISO string using Clock service
 */
export const currentTimeIso: Effect.Effect<string> = Clock.currentTimeMillis.pipe(
  Effect.map(formatMsToIso),
)

/**
 * Calculate days elapsed since a timestamp
 */
export const daysSince = (timestampMs: number): Effect.Effect<number> =>
  Clock.currentTimeMillis.pipe(Effect.map((now) => (now - timestampMs) / (1000 * 60 * 60 * 24)))
