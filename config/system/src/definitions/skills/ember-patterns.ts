/**
 * Ember Patterns Skill Definition
 *
 * Ember platform patterns for the voice memory application.
 * Migrated from: config/claude-code/skills/ember-patterns/SKILL.md
 */
import type { SystemSkill } from '@/schema'

export const emberPatternsSkill: SystemSkill = {
  name: 'ember-patterns' as SystemSkill['name'],
  description:
    'Ember platform patterns including cookie configuration, API error handling, Result types, and test credentials. Use when working on the Ember codebase.',
  allowedTools: ['Read', 'Write', 'Grep'] as SystemSkill['allowedTools'],

  sections: [
    {
      title: 'Critical Cookie Configuration',
      patterns: [
        {
          title: 'Dynamic Secure Flag',
          description:
            'Cookies fail on localhost if secure: true. Always use dynamic configuration',
          annotation: 'do',
          language: 'typescript',
          code: `const isLocalhost = url.hostname === "localhost" || url.hostname === "127.0.0.1";

setCookie(c, "session_id", sessionId, {
  httpOnly: true,
  secure: !isLocalhost,  // MUST be dynamic
  sameSite: "Lax",
  path: "/",
  maxAge: 60 * 60 * 24 * 7, // 7 days
});`,
        },
      ],
    },
    {
      title: 'API Error Parsing',
      patterns: [
        {
          title: 'Defensive Error Parsing',
          description: 'Always parse error responses defensively',
          annotation: 'do',
          language: 'typescript',
          code: `const err = await response.json().catch(() => ({}));
return {
  ok: false,
  error: err.error ?? err.message ?? \`HTTP \${response.status}\`
};`,
        },
      ],
    },
    {
      title: 'Test Credentials',
      content: `For local development and testing:
- Phone: \`5550000000\`
- OTP Code: \`123456\``,
    },
    {
      title: 'Result Type Pattern',
      patterns: [
        {
          title: 'Ember Result Type',
          annotation: 'do',
          language: 'typescript',
          code: `type Result<T, E = string> =
  | { ok: true; data: T }
  | { ok: false; error: E };

function parseUser(input: unknown): Result<User> {
  const parsed = UserSchema.safeParse(input);
  if (!parsed.success) {
    return { ok: false, error: parsed.error.message };
  }
  return { ok: true, data: parsed.data };
}`,
        },
      ],
    },
    {
      title: 'Monorepo Structure',
      patterns: [
        {
          title: 'Project Layout',
          annotation: 'info',
          language: 'text',
          code: `ember-platform/
├── apps/
│   ├── web/          # React frontend (TanStack Router)
│   ├── api/          # Hono API (Cloudflare Workers)
│   └── agent/        # Python voice agent (livekit-agents)
├── packages/
│   ├── domain/       # Shared Zod schemas and types
│   └── ui/           # Shared React components
└── package.json      # Bun workspace root`,
        },
      ],
    },
  ],
}
