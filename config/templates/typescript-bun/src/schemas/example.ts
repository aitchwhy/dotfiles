/**
 * Example Zod Schemas
 *
 * Schema-first development: Schema is source of truth, types are derived.
 */
import { z } from 'zod';

// ============================================================================
// Branded Types
// ============================================================================

declare const __brand: unique symbol;
type Brand<T, B extends string> = T & { readonly [__brand]: B };

/**
 * Create a branded ID schema
 */
const brandedId = <B extends string>(_brand: B) =>
  z.string().uuid().transform((id) => id as Brand<string, B>);

// ============================================================================
// Example: User Schema
// ============================================================================

export const UserIdSchema = brandedId('UserId');
export type UserId = z.infer<typeof UserIdSchema>;

export const UserSchema = z.object({
  id: UserIdSchema,
  email: z.string().email(),
  name: z.string().min(1).max(100),
  role: z.enum(['user', 'admin', 'moderator']),
  createdAt: z.coerce.date(),
});

export type User = z.infer<typeof UserSchema>;

// Input type for creation (without generated fields)
export const CreateUserSchema = UserSchema.omit({ id: true, createdAt: true });
export type CreateUser = z.infer<typeof CreateUserSchema>;

// ============================================================================
// Example Usage
// ============================================================================

/**
 * Parse unknown data into a validated User
 */
export function parseUser(data: unknown): User {
  return UserSchema.parse(data);
}

/**
 * Safe parse with Result-like pattern
 */
export function safeParseUser(data: unknown): z.SafeParseReturnType<unknown, User> {
  return UserSchema.safeParse(data);
}
