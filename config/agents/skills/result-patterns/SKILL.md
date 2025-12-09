---
name: result-patterns
description: Comprehensive Result type patterns for error handling. Never throw for expected failures. Chain operations. Handle all branches.
allowed-tools: Read, Write, Edit
---

## Core Definition

### Result Type

Base Result type for operations that can fail:

```typescript
export type Result<T, E = Error> =
  | { readonly ok: true; readonly data: T }
  | { readonly ok: false; readonly error: E };

export const Ok = <T>(data: T): Result<T, never> => ({ ok: true, data });
export const Err = <E>(error: E): Result<never, E> => ({ ok: false, error });
export const isOk = <T, E>(r: Result<T, E>): r is { ok: true; data: T } => r.ok;
export const isErr = <T, E>(r: Result<T, E>): r is { ok: false; error: E } => !r.ok;
```

## Transformation Functions

### Map and FlatMap

```typescript
function map<T, U, E>(result: Result<T, E>, fn: (t: T) => U): Result<U, E> {
  return result.ok ? Ok(fn(result.data)) : result;
}

function flatMap<T, U, E>(result: Result<T, E>, fn: (t: T) => Result<U, E>): Result<U, E> {
  return result.ok ? fn(result.data) : result;
}

function unwrapOr<T, E>(result: Result<T, E>, defaultValue: T): T {
  return result.ok ? result.data : defaultValue;
}
```

## Combining Results

### All and Partition

```typescript
function all<T, E>(results: readonly Result<T, E>[]): Result<T[], E> {
  const data: T[] = [];
  for (const result of results) {
    if (!result.ok) return result;
    data.push(result.data);
  }
  return Ok(data);
}

function partition<T, E>(results: readonly Result<T, E>[]): { successes: T[]; errors: E[] } {
  const successes: T[] = [];
  const errors: E[] = [];
  for (const result of results) {
    if (result.ok) successes.push(result.data);
    else errors.push(result.error);
  }
  return { successes, errors };
}
```

## Async Result Patterns

### tryCatch Wrapper

```typescript
export type AsyncResult<T, E = Error> = Promise<Result<T, E>>;

async function tryCatch<T>(fn: () => Promise<T>): Promise<Result<T, Error>> {
  try {
    return Ok(await fn());
  } catch (e) {
    return Err(e instanceof Error ? e : new Error(String(e)));
  }
}
```

## API Error Types

### Standard Error Constructors

```typescript
export type ApiError = { code: string; message: string; status: number };

export const notFound = (entity: string): ApiError => ({
  code: 'NOT_FOUND', message: `${entity} not found`, status: 404,
});

export const badRequest = (message: string): ApiError => ({
  code: 'BAD_REQUEST', message, status: 400,
});
```
