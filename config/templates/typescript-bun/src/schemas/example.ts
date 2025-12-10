/**
 * Example Zod Schemas - TypeScript-First Pattern
 *
 * TypeScript type is source of truth. Schema satisfies the type.
 * NEVER use z.infer<> - define the type explicitly first.
 */
import { z } from 'zod';

// ============================================================================
// Branded Types (TypeScript source of truth)
// ============================================================================

declare const __brand: unique symbol;
type Brand<T, B extends string> = T & { readonly [__brand]: B };

/** Branded User ID type */
type UserId = Brand<string, 'UserId'>;

// ============================================================================
// Domain Types (TypeScript source of truth)
// ============================================================================

/**
 * User domain type - the canonical definition
 */
type User = {
  readonly id: UserId;
  readonly email: string;
  readonly name: string;
  readonly role: 'user' | 'admin' | 'moderator';
  readonly createdAt: Date;
};

/**
 * Input type for user creation (without generated fields)
 */
type CreateUser = Omit<User, 'id' | 'createdAt'>;

// ============================================================================
// Zod Schemas (satisfies the types)
// ============================================================================

/**
 * Schema for branded UserId - validates UUID format
 */
const UserIdSchema = z.string().uuid() as z.ZodType<UserId>;

/**
 * Schema for User - validates all fields
 * Uses `satisfies` to ensure schema matches TypeScript type
 */
export const UserSchema = z.object({
  id: UserIdSchema,
  email: z.string().email(),
  name: z.string().min(1).max(100),
  role: z.enum(['user', 'admin', 'moderator']),
  createdAt: z.coerce.date(),
}) satisfies z.ZodType<User>;

/**
 * Schema for CreateUser input
 */
export const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  role: z.enum(['user', 'admin', 'moderator']),
}) satisfies z.ZodType<CreateUser>;

// ============================================================================
// Type Exports (from TypeScript, not from Zod)
// ============================================================================

export type { User, UserId, CreateUser };

// ============================================================================
// Parse Functions
// ============================================================================

/**
 * Parse unknown data into a validated User
 * @throws ZodError if validation fails
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
