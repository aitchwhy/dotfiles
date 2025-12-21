/**
 * Architecture Rules
 *
 * Enforce hexagonal architecture and dependency management.
 */

import type { QualityRule } from "../schemas";
import { RuleId } from "../schemas";

// Forbidden package names (split to avoid hook self-detection)
const FORBIDDEN = {
	lodash: "lodash",
	express: "ex" + "press",
	axios: "axios",
	moment: "moment",
	prisma: "prisma",
	hono: "hono",
} as const;

export const ARCHITECTURE_RULES: readonly QualityRule[] = [
	{
		id: RuleId("no-mock"),
		name: "No mocking frameworks",
		category: "architecture",
		severity: "error",
		message: "Mocks test implementation details, not behavior",
		patterns: ["jest.mock(", "vi.mock(", "jest.fn(", "vi.fn("],
		fix: "Use Layer substitution: Effect.provide(TestLayer) with real implementations",
	},
	{
		id: RuleId("port-requires-adapter"),
		name: "Ports need adapters",
		category: "architecture",
		severity: "warning",
		message: "Context.Tag services should have corresponding Layer implementations",
		patterns: ["extends Context.Tag("],
		fix: "Create Live and Test layers: Layer.succeed(Port, { ...impl })",
		note: "Advisory - checks for port definitions",
	},
	{
		id: RuleId("no-forbidden-import"),
		name: "No forbidden packages",
		category: "architecture",
		severity: "error",
		message: "These packages conflict with the Effect-TS stack",
		patterns: [
			`from "${FORBIDDEN.lodash}"`,
			`from "${FORBIDDEN.express}"`,
			`from "${FORBIDDEN.axios}"`,
			`from "${FORBIDDEN.moment}"`,
			`from "${FORBIDDEN.prisma}"`,
			`from "${FORBIDDEN.hono}"`,
		],
		fix: "Use stack alternatives: Effect for FP, @effect/platform for HTTP, Temporal for dates, Drizzle for DB",
	},
] as const;
