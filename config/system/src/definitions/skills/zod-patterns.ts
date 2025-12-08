/**
 * Zod Patterns Skill Definition
 *
 * Schema-first development with Zod v4.
 * Migrated from: config/claude-code/skills/zod-patterns/SKILL.md
 */
import type { SystemSkill } from '@/schema'

export const zodPatternsSkill: SystemSkill = {
  name: 'zod-patterns' as SystemSkill['name'],
  description:
    'Schema-first development with Zod v4. Schema is source of truth. Types are derived. Apply to any TypeScript project.',
  allowedTools: ['Read', 'Write', 'Edit'] as SystemSkill['allowedTools'],

  sections: [
    {
      title: 'Schema First, Type Second',
      patterns: [
        {
          title: 'Schema as Source of Truth',
          description: 'The schema is the source of truth. Types are always derived',
          annotation: 'do',
          language: 'typescript',
          code: `import { z } from 'zod';

export const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string().min(1).max(100),
  role: z.enum(['admin', 'user', 'guest']),
  createdAt: z.coerce.date(),
});

export type User = z.infer<typeof UserSchema>;

export const CreateUserSchema = UserSchema.omit({ id: true, createdAt: true });
export type CreateUser = z.infer<typeof CreateUserSchema>;`,
        },
      ],
    },
    {
      title: 'Branded Types with Zod',
      patterns: [
        {
          title: 'Combine Validation with Branded Types',
          annotation: 'do',
          language: 'typescript',
          code: `declare const __brand: unique symbol;
type Brand<T, B extends string> = T & { readonly [__brand]: B };

const brandedId = <B extends string>(brand: B) =>
  z.string().uuid().transform((id) => id as Brand<string, B>);

export const UserIdSchema = brandedId('UserId');
export type UserId = z.infer<typeof UserIdSchema>;`,
        },
      ],
    },
    {
      title: 'Result Type Integration',
      patterns: [
        {
          title: 'Wrap Zod Parsing in Result',
          annotation: 'do',
          language: 'typescript',
          code: `function parseWithResult<T>(schema: z.ZodType<T>, data: unknown): Result<T, ValidationError> {
  const result = schema.safeParse(data);
  if (result.success) {
    return { ok: true, data: result.data };
  }
  return {
    ok: false,
    error: { code: 'VALIDATION_ERROR', issues: result.error.issues },
  };
}`,
        },
      ],
    },
    {
      title: 'Transforms and Refinements',
      patterns: [
        {
          title: 'Coercion and Custom Validation',
          annotation: 'do',
          language: 'typescript',
          code: `export const PasswordSchema = z
  .string()
  .min(8)
  .refine((pw) => /[A-Z]/.test(pw), 'Must contain uppercase')
  .refine((pw) => /[0-9]/.test(pw), 'Must contain number');

export const DateRangeSchema = z
  .object({ startDate: z.coerce.date(), endDate: z.coerce.date() })
  .refine((d) => d.endDate > d.startDate, { message: 'End must be after start' });`,
        },
      ],
    },
    {
      title: 'Environment Variables',
      patterns: [
        {
          title: 'Type-Safe Env Vars',
          annotation: 'do',
          language: 'typescript',
          code: `export const EnvSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']),
  DATABASE_URL: z.string().url(),
  PORT: z.coerce.number().int().positive().default(3000),
});

export const env = EnvSchema.parse(process.env);`,
        },
      ],
    },
  ],
}
