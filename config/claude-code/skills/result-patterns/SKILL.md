---
name: result-patterns
description: Comprehensive Result type patterns for error handling. Never throw for expected failures. Chain operations. Handle all branches.
allowed-tools: Read, Write, Edit
---

# Result Type Patterns (December 2025)

## Core Definition

```typescript
// src/lib/result/index.ts

/**
 * Result type for operations that can fail.
 * Use instead of throwing for expected failures.
 */
export type Result<T, E = Error> =
  | { readonly ok: true; readonly data: T }
  | { readonly ok: false; readonly error: E };

/** Success constructor */
export const Ok = <T>(data: T): Result<T, never> => ({ ok: true, data });

/** Error constructor */
export const Err = <E>(error: E): Result<never, E> => ({ ok: false, error });

/** Type guard for success */
export const isOk = <T, E>(r: Result<T, E>): r is { ok: true; data: T } => r.ok;

/** Type guard for error */
export const isErr = <T, E>(r: Result<T, E>): r is { ok: false; error: E } => !r.ok;
```

## Transformation Functions

```typescript
/** Transform the success value */
export function map<T, U, E>(result: Result<T, E>, fn: (t: T) => U): Result<U, E> {
  if (result.ok) {
    return Ok(fn(result.data));
  }
  return result;
}

/** Chain operations that return Results */
export function flatMap<T, U, E>(
  result: Result<T, E>,
  fn: (t: T) => Result<U, E>
): Result<U, E> {
  if (result.ok) {
    return fn(result.data);
  }
  return result;
}

/** Transform the error value */
export function mapErr<T, E, F>(
  result: Result<T, E>,
  fn: (e: E) => F
): Result<T, F> {
  if (!result.ok) {
    return Err(fn(result.error));
  }
  return result;
}

/** Get value or default */
export function unwrapOr<T, E>(result: Result<T, E>, defaultValue: T): T {
  return result.ok ? result.data : defaultValue;
}

/** Get value or compute default */
export function unwrapOrElse<T, E>(result: Result<T, E>, fn: (e: E) => T): T {
  return result.ok ? result.data : fn(result.error);
}

/** Throw if error (use sparingly, only at boundaries) */
export function unwrap<T, E>(result: Result<T, E>): T {
  if (result.ok) {
    return result.data;
  }
  throw result.error;
}
```

## Combining Results

```typescript
/** Collect all successes or return first error */
export function all<T, E>(results: readonly Result<T, E>[]): Result<T[], E> {
  const data: T[] = [];
  for (const result of results) {
    if (!result.ok) return result;
    data.push(result.data);
  }
  return Ok(data);
}

/** Separate successes and errors */
export function partition<T, E>(
  results: readonly Result<T, E>[]
): { successes: T[]; errors: E[] } {
  const successes: T[] = [];
  const errors: E[] = [];
  for (const result of results) {
    if (result.ok) {
      successes.push(result.data);
    } else {
      errors.push(result.error);
    }
  }
  return { successes, errors };
}

/** Combine two results */
export function zip<T1, T2, E>(
  r1: Result<T1, E>,
  r2: Result<T2, E>
): Result<[T1, T2], E> {
  if (!r1.ok) return r1;
  if (!r2.ok) return r2;
  return Ok([r1.data, r2.data]);
}
```

## Async Result Patterns

```typescript
export type AsyncResult<T, E = Error> = Promise<Result<T, E>>;

/** Wrap a potentially throwing async function */
export async function tryCatch<T>(
  fn: () => Promise<T>
): Promise<Result<T, Error>> {
  try {
    return Ok(await fn());
  } catch (e) {
    return Err(e instanceof Error ? e : new Error(String(e)));
  }
}

/** Chain async results */
export async function flatMapAsync<T, U, E>(
  result: AsyncResult<T, E>,
  fn: (t: T) => AsyncResult<U, E>
): AsyncResult<U, E> {
  const r = await result;
  if (!r.ok) return r;
  return fn(r.data);
}

/** Map over async result */
export async function mapAsync<T, U, E>(
  result: AsyncResult<T, E>,
  fn: (t: T) => U | Promise<U>
): AsyncResult<U, E> {
  const r = await result;
  if (!r.ok) return r;
  return Ok(await fn(r.data));
}

/** Run multiple async results in parallel */
export async function allAsync<T, E>(
  results: readonly AsyncResult<T, E>[]
): AsyncResult<T[], E> {
  const settled = await Promise.all(results);
  return all(settled);
}
```

## API Error Types

```typescript
export type ApiError = {
  code: string;
  message: string;
  status: number;
  details?: unknown;
};

export const notFound = (entity: string): ApiError => ({
  code: 'NOT_FOUND',
  message: `${entity} not found`,
  status: 404,
});

export const badRequest = (message: string): ApiError => ({
  code: 'BAD_REQUEST',
  message,
  status: 400,
});

export const unauthorized = (message = 'Unauthorized'): ApiError => ({
  code: 'UNAUTHORIZED',
  message,
  status: 401,
});

export const forbidden = (message = 'Forbidden'): ApiError => ({
  code: 'FORBIDDEN',
  message,
  status: 403,
});

export const conflict = (message: string): ApiError => ({
  code: 'CONFLICT',
  message,
  status: 409,
});

export const internal = (message = 'Internal server error'): ApiError => ({
  code: 'INTERNAL_ERROR',
  message,
  status: 500,
});
```

## React Integration

```typescript
import { useState, useCallback, useEffect } from 'react';

export function useAsyncResult<T, E>(
  asyncFn: () => Promise<Result<T, E>>,
  deps: readonly unknown[]
) {
  const [result, setResult] = useState<Result<T, E> | null>(null);
  const [loading, setLoading] = useState(true);

  const execute = useCallback(async () => {
    setLoading(true);
    try {
      const r = await asyncFn();
      setResult(r);
    } finally {
      setLoading(false);
    }
  }, deps);

  useEffect(() => {
    execute();
  }, [execute]);

  return { result, loading, refetch: execute };
}

// Usage
function UserProfile({ userId }: { userId: string }) {
  const { result, loading, refetch } = useAsyncResult(
    () => fetchUser(userId),
    [userId]
  );

  if (loading) return <Spinner />;
  if (!result) return null;
  if (!result.ok) return <ErrorDisplay error={result.error} onRetry={refetch} />;

  return <ProfileCard user={result.data} />;
}
```

## HonoJS Integration

```typescript
import { Hono } from 'hono';

const app = new Hono();

app.get('/users/:id', async (c) => {
  const userId = c.req.param('id');
  const result = await getUser(userId);

  if (!result.ok) {
    const { error } = result;
    return c.json(
      { error: { code: error.code, message: error.message } },
      error.status as 400 | 404 | 500
    );
  }

  return c.json({ data: result.data });
});
```
