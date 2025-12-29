# SSOT TypeScript Stack (Dec 2025)

## Philosophy

Source-only TypeScript: packages export `./src/index.ts`, never compiled.
Apps bundle with esbuild for production. Zero tsc in CI.

## Toolchain

| Tool     | Purpose       | Command                          |
| -------- | ------------- | -------------------------------- |
| tsx      | Dev runtime   | `tsx watch src/server.ts`        |
| tsgo     | Type checking | `tsgo --project tsconfig.json`   |
| esbuild  | Prod bundles  | `esbuild src/server.ts --bundle` |
| oxlint   | Linting       | `oxlint`                         |
| biome    | Formatting    | `biome check --write .`          |
| ast-grep | Custom rules  | `ast-grep scan`                  |
| lefthook | Git hooks     | Auto via `prepare`               |
| vitest   | Testing       | `vitest run`                     |

## Package Exports (Source-Only)

```json
{
  "exports": {
    ".": "./src/index.ts"
  }
}
```

Never:

- `./dist/index.js`
- Conditional exports with `types`/`import`
- `rewriteRelativeImportExtensions`
- vitest aliases

## Effect-TS Patterns

- Zero try/catch → `Effect.try`, `Effect.gen`
- Zero console._ → `Effect.log_`, `Logger`
- Zero any → `unknown`, proper types
- Services via `Context.Tag` + `Layer`
- Errors as values via `Effect.fail`

## Version Pinning

All versions from `versions.json`. pnpm `overrides` in root for:

- effect ecosystem (single version)
- @types/node
- vitest

## Import Extensions

Always `.ts`:

```typescript
import { foo } from "./foo.ts";
export * from "./bar.ts";
```
