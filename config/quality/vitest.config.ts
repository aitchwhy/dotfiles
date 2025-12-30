import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    // Vitest 4.x best practices - explicit imports for better IDE support
    globals: false,
    environment: 'node',

    // Include both unit tests (co-located with src) and integration tests
    include: ['src/**/*.test.ts', 'tests/**/*.test.ts'],

    // Resilience settings for CI
    retry: process.env['CI'] ? 2 : 0,
    testTimeout: 10_000,
    hookTimeout: 10_000,

    // Coverage configuration (v8 provider is fastest)
    coverage: {
      provider: 'v8',
      include: ['src/**/*.ts'],
      exclude: ['**/*.test.ts', '**/*.d.ts', 'src/generate.ts'],
    },
  },

  // NOTE: Path aliases removed - use relative imports per STACK.md
})
