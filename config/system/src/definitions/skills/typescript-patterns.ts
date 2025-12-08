/**
 * TypeScript Patterns Skill Definition
 *
 * Elite TypeScript patterns for December 2025.
 * Migrated from: config/claude-code/skills/typescript-patterns/SKILL.md
 */
import type { SystemSkill } from '@/schema'

export const typescriptPatternsSkill: SystemSkill = {
  name: 'typescript-patterns' as SystemSkill['name'],
  description:
    "Elite TypeScript patterns for December 2025. Parse don't validate. Make illegal states unrepresentable. Apply to ANY TypeScript project.",
  allowedTools: ['Read', 'Write', 'Edit'] as SystemSkill['allowedTools'],

  sections: [
    {
      title: 'Branded Types for Type-Safe Identifiers',
      patterns: [
        {
          title: 'Brand Infrastructure',
          description: 'Never use raw strings for identifiers. Compile-time safety for free',
          annotation: 'do',
          language: 'typescript',
          code: `declare const __brand: unique symbol;
type Brand<T, B extends string> = T & { readonly [__brand]: B };

type UserId = Brand<string, 'UserId'>;
type OrderId = Brand<string, 'OrderId'>;

const UserId = (id: string): UserId => id as UserId;

function getUser(id: UserId): Promise<User> { ... }
getUser(orderId); // Type error! OrderId is not assignable to UserId`,
        },
      ],
    },
    {
      title: 'Result Types for Fallible Operations',
      patterns: [
        {
          title: 'Core Result Type',
          description: 'Never throw for expected failures. Make error handling explicit',
          annotation: 'do',
          language: 'typescript',
          code: `type Result<T, E = Error> =
  | { readonly ok: true; readonly data: T }
  | { readonly ok: false; readonly error: E };

const Ok = <T>(data: T): Result<T, never> => ({ ok: true, data });
const Err = <E>(error: E): Result<never, E> => ({ ok: false, error });`,
        },
      ],
    },
    {
      title: 'Discriminated Unions for State Machines',
      patterns: [
        {
          title: 'Make Invalid States Unrepresentable',
          description: 'Each state has exactly the fields it needs',
          annotation: 'do',
          language: 'typescript',
          code: `type Request =
  | { readonly status: 'idle' }
  | { readonly status: 'loading'; readonly startedAt: number }
  | { readonly status: 'success'; readonly data: ResponseData }
  | { readonly status: 'error'; readonly error: Error };`,
        },
      ],
    },
    {
      title: "Parse Don't Validate",
      patterns: [
        {
          title: 'Validate at Boundaries',
          description: 'Parse once at boundary, fully typed internally',
          annotation: 'do',
          language: 'typescript',
          code: `function processUser(data: unknown): Result<ProcessedUser, ValidationError> {
  const parsed = UserSchema.safeParse(data);
  if (!parsed.success) {
    return Err({ code: 'VALIDATION_ERROR', issues: parsed.error.issues });
  }
  return Ok(transformToProcessedUser(parsed.data));
}`,
        },
      ],
    },
    {
      title: 'Const Assertions and Satisfies',
      patterns: [
        {
          title: 'Literal Types and Type Checking',
          annotation: 'do',
          language: 'typescript',
          code: `const ROLES = ['admin', 'user', 'guest'] as const;
type Role = (typeof ROLES)[number];

const config = {
  apiUrl: 'https://api.example.com',
  timeout: 5000,
} satisfies Record<string, string | number>;`,
        },
      ],
    },
  ],
}
