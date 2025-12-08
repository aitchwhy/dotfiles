/**
 * Hono Workers Skill Definition
 *
 * Hono on Cloudflare Workers patterns.
 * Migrated from: config/claude-code/skills/hono-workers/SKILL.md
 */
import type { SystemSkill } from '@/schema'

export const honoWorkersSkill: SystemSkill = {
  name: 'hono-workers' as SystemSkill['name'],
  description:
    'Hono on Cloudflare Workers patterns including environment access, typed bindings, and middleware. Use when working with Hono APIs on Workers.',
  allowedTools: ['Read', 'Write'] as SystemSkill['allowedTools'],

  sections: [
    {
      title: 'Environment Access',
      patterns: [
        {
          title: 'Use Context Bindings',
          description: "Workers don't have process.env. Use context bindings",
          annotation: 'do',
          language: 'typescript',
          code: `// WRONG: process.env doesn't exist in Workers
const token = process.env.API_KEY;

// RIGHT: Use context bindings
const token = c.env.API_KEY;`,
        },
      ],
    },
    {
      title: 'Typed Bindings',
      patterns: [
        {
          title: 'Always Type Environment',
          annotation: 'do',
          language: 'typescript',
          code: `type Env = {
  DATABASE_URL: string;
  API_KEY: string;
  KV_STORE: KVNamespace;
  R2_BUCKET: R2Bucket;
};

const app = new Hono<{ Bindings: Env }>();`,
        },
      ],
    },
    {
      title: 'Middleware Pattern',
      patterns: [
        {
          title: 'Auth Middleware',
          annotation: 'do',
          language: 'typescript',
          code: `import { createMiddleware } from 'hono/factory';

const authMiddleware = createMiddleware<{ Bindings: Env }>(
  async (c, next) => {
    const session = await getSession(c);
    if (!session) {
      return c.json({ error: 'Unauthorized' }, 401);
    }
    c.set('session', session);
    await next();
  }
);`,
        },
      ],
    },
    {
      title: 'Zod Validation',
      patterns: [
        {
          title: 'Request Validation',
          annotation: 'do',
          language: 'typescript',
          code: `import { zValidator } from '@hono/zod-validator';
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
);`,
        },
      ],
    },
    {
      title: 'Error Handling',
      patterns: [
        {
          title: 'Global Error Handler',
          annotation: 'do',
          language: 'typescript',
          code: `app.onError((err, c) => {
  console.error(err);
  return c.json({ ok: false, error: err.message }, 500);
});`,
        },
      ],
    },
  ],
}
