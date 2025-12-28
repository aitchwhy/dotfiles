import type { Memory } from '../schemas'

export const PATTERN_MEMORIES: Memory[] = [
  {
    id: 'thin-handlers',
    category: 'pattern',
    title: 'Thin API Handlers',
    content:
      'Handlers (HttpApiBuilder.group) are thin orchestration only. ' +
      'NEVER contain business logic. Pattern: parse request -> call capability -> format response. ' +
      'Delegate logic to Repository/Domain.',
    verified: '2025-12-28',
  },
  {
    id: 'dependency-injection',
    category: 'pattern',
    title: 'Type-Safe Dependency Injection',
    content:
      'Use Context.Tag for capabilities (interfaces). Use Layer for implementations. ' +
      'Compose in runtime/AppLive.ts using Layer.mergeAll. No manual DI containers.',
    verified: '2025-12-28',
  },
  {
    id: 'xstate-patterns',
    category: 'pattern',
    title: 'XState v5 Patterns',
    content:
      'Use discriminated union contexts (phase: idle|loading|loaded|error). ' +
      'Use setup() factory pattern. Bridge Effect to XState via runPromise helpers. ' +
      'Explicit states over implicit boolean flags.',
    verified: '2025-12-28',
  },
  {
    id: 'testing-strategy',
    category: 'pattern',
    title: '3-Tier Testing Strategy',
    content:
      '1. E2E (Playwright) for critical user journeys/auth. ' +
      '2. Integration (TestContainers) for API/Database. ' +
      '3. Unit (Vitest+Effect) for Pure Domain logic. ' +
      'Auth Tier 2: Reuse storageState json for speed.',
    verified: '2025-12-28',
  },
  {
    id: 'import-ordering',
    category: 'constraint',
    title: 'Strict Import Ordering',
    content:
      '1. External (effect, react). 2. Workspace (@scope/domain). 3. Relative (../). ' +
      'Enforced by Biome. Always use barrel imports from packages (e.g. import { ... } from "@scope/ui").',
    verified: '2025-12-28',
  },
  {
    id: 'no-env-files',
    category: 'constraint',
    title: 'No .env Files',
    content:
      'Use direnv + Pulumi ESC for secrets. ' +
      'Config package (@scope/config) is SSOT for EnvSchema. ' +
      'eval $(pulumi env open project/dev --format shell).',
    verified: '2025-12-28',
  },
]
