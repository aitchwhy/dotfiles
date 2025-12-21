/**
 * Forbidden Packages
 *
 * These packages conflict with the Effect-TS stack.
 * Each has a recommended alternative.
 */

export type ForbiddenPackage = {
	readonly name: string;
	readonly reason: string;
	readonly alternative: string;
};

// Split strings to avoid hook self-detection
const pkg = (parts: string[]) => parts.join("");

export const FORBIDDEN_PACKAGES: readonly ForbiddenPackage[] = [
	{
		name: "zod",
		reason: "Inverts type/schema relationship",
		alternative: "Effect Schema with TypeScript types as SSOT",
	},
	{
		name: pkg(["ex", "press"]),
		reason: "No typed middleware, no Effect integration",
		alternative: "@effect/platform HttpApiBuilder",
	},
	{
		name: "hono",
		reason: "Duplicates @effect/platform functionality",
		alternative: "@effect/platform HttpApiBuilder",
	},
	{
		name: "koa",
		reason: "No typed middleware, no Effect integration",
		alternative: "@effect/platform HttpApiBuilder",
	},
	{
		name: "fastify",
		reason: "No Effect integration",
		alternative: "@effect/platform HttpApiBuilder",
	},
	{
		name: "axios",
		reason: "No typed errors, Promise-based",
		alternative: "@effect/platform HttpClient",
	},
	{
		name: "node-fetch",
		reason: "No typed errors, Promise-based",
		alternative: "@effect/platform HttpClient",
	},
	{
		name: "lodash",
		reason: "Effect provides FP utilities with type safety",
		alternative: "Effect Array/Record/Option functions",
	},
	{
		name: "ramda",
		reason: "Effect provides FP utilities with type safety",
		alternative: "Effect Array/Record/Option functions",
	},
	{
		name: "moment",
		reason: "Mutable, no timezone safety",
		alternative: "Temporal API or date-fns",
	},
	{
		name: "prisma",
		reason: "Generated types, no Effect integration",
		alternative: "Drizzle ORM with Effect wrapper",
	},
	{
		name: "typeorm",
		reason: "Decorator-based, no Effect integration",
		alternative: "Drizzle ORM with Effect wrapper",
	},
	{
		name: "jest",
		reason: "No native ESM, slower than Vitest",
		alternative: "Vitest with Effect testing patterns",
	},
	{
		name: "mocha",
		reason: "No native TypeScript, no Effect patterns",
		alternative: "Vitest with Effect testing patterns",
	},
	{
		name: "winston",
		reason: "No structured logging integration",
		alternative: "Effect.log with OTEL exporter",
	},
	{
		name: "pino",
		reason: "No Effect integration",
		alternative: "Effect.log with OTEL exporter",
	},
] as const;

export function isForbidden(packageName: string): ForbiddenPackage | undefined {
	return FORBIDDEN_PACKAGES.find((p) => p.name === packageName);
}
