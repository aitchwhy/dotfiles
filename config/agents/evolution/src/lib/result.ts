/**
 * Result Type Implementation
 *
 * Never throw for expected failures. Use Result types for all fallible operations.
 */

// ============================================================================
// Core Result Type
// ============================================================================

export type Result<T, E = Error> =
  | { readonly ok: true; readonly data: T }
  | { readonly ok: false; readonly error: E };

// ============================================================================
// Constructor Functions
// ============================================================================

export const Ok = <T>(data: T): Result<T, never> => ({ ok: true, data });
export const Err = <E>(error: E): Result<never, E> => ({ ok: false, error });

// ============================================================================
// Type Guards
// ============================================================================

export const isOk = <T, E>(result: Result<T, E>): result is { ok: true; data: T } => result.ok;

export const isErr = <T, E>(result: Result<T, E>): result is { ok: false; error: E } => !result.ok;

// ============================================================================
// Utility Functions
// ============================================================================

/**
 * Unwrap a Result, throwing if it's an error
 * Only use when you've already checked or are certain it's Ok
 */
export const unwrap = <T, E>(result: Result<T, E>): T => {
  if (result.ok) return result.data;
  throw result.error instanceof Error ? result.error : new Error(String(result.error));
};

/**
 * Unwrap a Result with a default value
 */
export const unwrapOr = <T, E>(result: Result<T, E>, defaultValue: T): T => {
  return result.ok ? result.data : defaultValue;
};

/**
 * Map over the success value
 */
export const map = <T, U, E>(result: Result<T, E>, fn: (value: T) => U): Result<U, E> => {
  return result.ok ? Ok(fn(result.data)) : result;
};

/**
 * Map over the error value
 */
export const mapErr = <T, E, F>(result: Result<T, E>, fn: (error: E) => F): Result<T, F> => {
  return result.ok ? result : Err(fn(result.error));
};

/**
 * Chain Results (flatMap/bind)
 */
export const andThen = <T, U, E>(
  result: Result<T, E>,
  fn: (value: T) => Result<U, E>
): Result<U, E> => {
  return result.ok ? fn(result.data) : result;
};

/**
 * Try/catch wrapper that returns a Result
 */
export const tryCatch = <T>(fn: () => T): Result<T, Error> => {
  try {
    return Ok(fn());
  } catch (e) {
    return Err(e instanceof Error ? e : new Error(String(e)));
  }
};

/**
 * Async try/catch wrapper
 */
export const tryCatchAsync = async <T>(fn: () => Promise<T>): Promise<Result<T, Error>> => {
  try {
    return Ok(await fn());
  } catch (e) {
    return Err(e instanceof Error ? e : new Error(String(e)));
  }
};

/**
 * Combine multiple Results into a single Result of an array
 */
export const all = <T, E>(results: readonly Result<T, E>[]): Result<readonly T[], E> => {
  const values: T[] = [];
  for (const result of results) {
    if (!result.ok) return result;
    values.push(result.data);
  }
  return Ok(values);
};

/**
 * Combine Results from an object
 */
export const allFromObject = <T extends Record<string, Result<unknown, Error>>>(
  obj: T
): Result<{ [K in keyof T]: T[K] extends Result<infer V, Error> ? V : never }, Error> => {
  const result: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(obj)) {
    if (!value.ok) return value;
    result[key] = value.data;
  }
  return Ok(result as { [K in keyof T]: T[K] extends Result<infer V, Error> ? V : never });
};
