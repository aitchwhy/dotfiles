---
name: ember-patterns
description: Ember platform patterns including cookie configuration, API error handling, Result types, and test credentials. Use when working on the Ember codebase.
allowed-tools: Read, Write, Grep
---

## Critical Cookie Configuration

### Dynamic Secure Flag

Cookies fail on localhost if secure: true. Always use dynamic configuration:

```typescript
const isLocalhost = url.hostname === "localhost" || url.hostname === "127.0.0.1";

setCookie(c, "session_id", sessionId, {
  httpOnly: true,
  secure: !isLocalhost,  // MUST be dynamic
  sameSite: "Lax",
  path: "/",
  maxAge: 60 * 60 * 24 * 7, // 7 days
});
```

## API Error Parsing

### Defensive Error Parsing

Always parse error responses defensively:

```typescript
const err = await response.json().catch(() => ({}));
return {
  ok: false,
  error: err.error ?? err.message ?? `HTTP ${response.status}`
};
```

## Test Credentials

For local development and testing:
- Phone: `5550000000`
- OTP Code: `123456`

## Result Type Pattern

### Ember Result Type

```typescript
type Result<T, E = string> =
  | { ok: true; data: T }
  | { ok: false; error: E };

function parseUser(input: unknown): Result<User> {
  const parsed = UserSchema.safeParse(input);
  if (!parsed.success) {
    return { ok: false, error: parsed.error.message };
  }
  return { ok: true, data: parsed.data };
}
```

## Monorepo Structure

### Project Layout

```
ember-platform/
├── apps/
│   ├── web/          # React frontend (TanStack Router)
│   ├── api/          # Hono API (Cloudflare Workers)
│   └── agent/        # Python voice agent (livekit-agents)
├── packages/
│   ├── domain/       # Shared Zod schemas and types
│   └── ui/           # Shared React components
└── package.json      # Bun workspace root
```
