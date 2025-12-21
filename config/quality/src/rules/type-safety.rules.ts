/**
 * Type Safety Rules
 *
 * Enforce strict typing - no escape hatches.
 */

import type { QualityRule } from "../schemas";
import { RuleId } from "../schemas";

export const TYPE_SAFETY_RULES: readonly QualityRule[] = [
	{
		id: RuleId("no-any"),
		name: "No any type",
		category: "type-safety",
		severity: "error",
		message: "The 'any' type bypasses type checking entirely",
		patterns: [": any", "as any", "<any>"],
		fix: "Use 'unknown' and narrow with type guards, or define proper types",
	},
	{
		id: RuleId("no-zod"),
		name: "No Zod schemas",
		category: "type-safety",
		severity: "error",
		message: "Zod inverts the type/schema relationship - use Effect Schema",
		patterns: ['from "zod"', "z.object", "z.infer", "z.string"],
		fix: "Use Effect Schema with TypeScript types as SSOT: Schema satisfies Schema.Schema<Type>",
	},
	{
		id: RuleId("require-branded-id"),
		name: "Require branded IDs",
		category: "type-safety",
		severity: "warning",
		message: "Plain string IDs allow mixing different entity types",
		patterns: ["userId: string", "orderId: string", "id: string"],
		fix: "Use branded types: type UserId = string & Brand.Brand<'UserId'>",
		note: "Advisory - triggers on common patterns but may have false positives",
	},
] as const;
