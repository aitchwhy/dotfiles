---
description: Generate Hono API endpoint for Ember
allowed-tools: Write, Read
---

# Create Ember API Endpoint: $ARGUMENTS

Generate a Hono endpoint following Ember patterns:

```typescript
import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import type { Env } from '../types';

const RequestSchema = z.object({
  // Define request schema
});

const ResponseSchema = z.object({
  // Define response schema
});

type Request = z.infer<typeof RequestSchema>;
type Response = z.infer<typeof ResponseSchema>;

export const ${ARGUMENTS}Route = new Hono<{ Bindings: Env }>()
  .post(
    '/${ARGUMENTS}',
    zValidator('json', RequestSchema),
    async (c) => {
      const data = c.req.valid('json');

      try {
        // Implementation

        return c.json({ ok: true, data: result } satisfies Response);
      } catch (error) {
        return c.json({ ok: false, error: 'Operation failed' }, 500);
      }
    }
  );
```

## Guidelines

- Zod validation at boundary
- Typed environment bindings
- Result type responses
- Error handling with proper status codes

## File Location

- `apps/api/src/routes/${ARGUMENTS}.ts`
- Register in `apps/api/src/index.ts`
