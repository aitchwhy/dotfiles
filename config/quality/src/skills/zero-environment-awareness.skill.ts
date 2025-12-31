/**
 * Zero Environment Awareness Skill
 *
 * Code receives behavior flags, not environment names.
 * Same binary runs anywhere - testable, portable, explicit.
 */

import type { SkillDefinition } from '../schemas'
import { SkillName } from '../schemas'

export const zeroEnvironmentAwarenessSkill: SkillDefinition = {
  frontmatter: {
    name: SkillName('zero-environment-awareness'),
    description:
      'IoC pattern where code receives behavior flags (showStackTraces: false) instead of checking environments (NODE_ENV)',
    allowedTools: ['Read', 'Write', 'Edit', 'Grep'],
    tokenBudget: 800,
  },
  sections: [
    {
      heading: 'Core Principle',
      content: `
**Zero Environment Awareness**: Code should receive concrete behavior specifications,
not environment identifiers. The code never asks "am I in production?" - it receives
\`{ showStackTraces: false, logLevel: "warn" }\`.

**Benefits:**
- **Testable** - inject any config without mocking environment variables
- **Portable** - same binary runs anywhere (local, CI, prod)
- **Explicit** - behaviors visible in config, not hidden in conditionals
`,
    },
    {
      heading: 'Anti-Patterns (NEVER Do)',
      content: `
\`\`\`typescript
// BAD - environment-aware conditionals
if (process.env.NODE_ENV === 'production') {
  enableDetailedErrors = false;
}

// BAD - environment variable checks
const isDev = import.meta.env.DEV;
if (isDev) { console.log('Debug:', data); }

// BAD - environment name comparisons
if (ENVIRONMENT === 'test') { skipRateLimiting = true; }

// BAD - even at "entry point"
const ConfigLive = Layer.succeed(Config, {
  showStackTraces: process.env.NODE_ENV !== 'production', // VIOLATION
});
\`\`\`
`,
    },
    {
      heading: 'Config Service Pattern (Effect-TS)',
      content: `
\`\`\`typescript
import { Context, Effect, Layer, Schema } from "effect";

// 1. Define Config with BEHAVIOR flags (not environment names)
class Config extends Context.Tag("Config")<Config, {
  readonly showStackTraces: boolean;
  readonly logLevel: "debug" | "info" | "warn" | "error";
  readonly apiTimeout: number;
  readonly enableMetrics: boolean;
  readonly rateLimitRps: number;
}>() {}

// 2. Schema for validation
const ConfigSchema = Schema.Struct({
  showStackTraces: Schema.Boolean,
  logLevel: Schema.Literal("debug", "info", "warn", "error"),
  apiTimeout: Schema.Number.pipe(Schema.positive()),
  enableMetrics: Schema.Boolean,
  rateLimitRps: Schema.Number.pipe(Schema.positive()),
});
\`\`\`
`,
    },
    {
      heading: 'External Config Loading',
      content: `
Config is loaded from **external sources** (files, CLI args), never process.env in code:

\`\`\`typescript
// config.production.json (or config.local.json, config.test.json)
{
  "showStackTraces": false,
  "logLevel": "warn",
  "apiTimeout": 30000,
  "enableMetrics": true,
  "rateLimitRps": 100
}

// main.ts - Load config from file path provided by CLI or bundler
import configRaw from "./config.json"; // Path resolved externally

const ConfigLive = Layer.succeed(Config,
  Schema.decodeUnknownSync(ConfigSchema)(configRaw)
);
\`\`\`

**Deployment patterns:**
- Docker: \`COPY config.production.json /app/config.json\`
- CLI: \`node app.js --config ./config.production.json\`
- Bundler: Configure build to include correct config file
`,
    },
    {
      heading: 'Test Config Layer',
      content: `
\`\`\`typescript
// ConfigTest - deterministic values for tests
const ConfigTest = Layer.succeed(Config, {
  showStackTraces: true,     // Verbose for debugging test failures
  logLevel: "debug" as const,
  apiTimeout: 1000,          // Fast timeouts for tests
  enableMetrics: false,      // No side effects
  rateLimitRps: 10000,       // No throttling in tests
});

// Usage in tests
describe("ErrorHandler", () => {
  it("shows stack trace when configured", async () => {
    const result = await Effect.runPromise(
      handleError(new Error("test")).pipe(
        Effect.provide(ConfigTest)
      )
    );
    expect(result).toContain("at Object");
  });
});
\`\`\`
`,
    },
    {
      heading: 'Usage - Zero Environment Knowledge',
      content: `
\`\`\`typescript
// This code has NO idea what "production" or "development" means
const handleError = (error: Error) =>
  Effect.gen(function* () {
    const config = yield* Config;

    // Behavior-driven, not environment-driven
    if (config.showStackTraces) {
      yield* Effect.log(error.stack ?? error.message);
    } else {
      yield* Effect.log(\`Error: \${error.message}\`);
    }

    if (config.enableMetrics) {
      yield* Metrics.increment("error_count");
    }
  });

// Same code works identically whether:
// - Running locally with ConfigTest
// - Running in CI with ConfigCI
// - Running in prod with ConfigLive
\`\`\`
`,
    },
    {
      heading: 'Guard 51 Enforcement',
      content: `
This pattern is enforced by **Guard 51: no-env-conditionals**:

**Blocked patterns:**
- \`NODE_ENV\`, \`ENVIRONMENT\`, \`IS_PROD\`, \`IS_DEV\`
- \`import.meta.env.MODE\`, \`import.meta.env.DEV\`, \`import.meta.env.PROD\`
- String comparisons: \`=== 'production'\`, \`=== 'development'\`, \`=== 'test'\`

**Also blocked by Guard 49 (no-process-env):**
- \`process.env.FOO\`, \`Bun.env.FOO\`

Together these guards ensure **complete environment isolation**.
`,
    },
    {
      heading: 'Migration Guide',
      content: `
**Step 1**: Identify all environment checks
\`\`\`bash
rg "NODE_ENV|process\\.env|import\\.meta\\.env" --type ts
\`\`\`

**Step 2**: Extract behaviors to Config interface
- \`NODE_ENV === 'production'\` -> \`showStackTraces: false\`
- \`NODE_ENV === 'development'\` -> \`logLevel: "debug"\`
- \`process.env.API_TIMEOUT\` -> \`apiTimeout: 30000\`

**Step 3**: Create environment-specific config files
- \`config.local.json\` (development behaviors)
- \`config.test.json\` (test behaviors)
- \`config.production.json\` (production behaviors)

**Step 4**: Update deployment to provide correct config file
`,
    },
  ],
}
