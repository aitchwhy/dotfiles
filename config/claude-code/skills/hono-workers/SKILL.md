---
name: hono-workers
description: Hono on Cloudflare Workers patterns including environment access, typed bindings, and middleware. Use when working with Hono APIs on Workers.
allowed-tools: Read, Write
---

# Hono on Cloudflare Workers

## Environment Access

Workers don't have `process.env`. Use context bindings:

```typescript
// WRONG: process.env doesn't exist in Workers
const token = process.env.API_KEY;

// RIGHT: Use context bindings
const token = c.env.API_KEY;
```

## Typed Bindings

Always type your environment bindings:

```typescript
type Env = {
  DATABASE_URL: string;
  API_KEY: string;
  SESSION_SECRET: string;
  KV_STORE: KVNamespace;
  R2_BUCKET: R2Bucket;
};

const app = new Hono<{ Bindings: Env }>();
```

## Middleware Pattern

```typescript
import { createMiddleware } from 'hono/factory';

const authMiddleware = createMiddleware<{ Bindings: Env }>(
  async (c, next) => {
    const session = await getSession(c);
    if (!session) {
      return c.json({ error: 'Unauthorized' }, 401);
    }
    c.set('session', session);
    await next();
  }
);
```

## Zod Validation

```typescript
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';

const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1),
});

app.post('/users',
  zValidator('json', CreateUserSchema),
  async (c) => {
    const data = c.req.valid('json');
    // data is typed as { email: string; name: string }
  }
);
```

## Error Handling

```typescript
app.onError((err, c) => {
  console.error(err);
  return c.json({
    ok: false,
    error: err.message
  }, 500);
});
```
