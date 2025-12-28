import type { Memory } from '../schemas'

export const STANDARDS_MEMORIES: Memory[] = [
  {
    id: 'ts-esm-purity',
    category: 'standard',
    title: 'Pure TypeScript + ESM',
    content:
      'Codebase must be Pure TypeScript with ESM (NodeNext). ' +
      'Zero .js files allowed in source. ' +
      'Packages must export `./src/index.ts` (Source-Only) and forbid `dist/` artifacts. ' +
      'Use `tsx` for runtime execution and `tsgo` for type-checking.',
    verified: '2025-12-28',
  },
  {
    id: 'effect-strictness',
    category: 'standard',
    title: 'Effect-TS Strictness',
    content:
      'Strict enforcement of Effect patterns: ' +
      '1. No try/catch (use Effect.try/tryPromise). ' +
      '2. Context.Tag must use string literal identifiers to avoid dual-package hazards. ' +
      '3. No native Promise usage (wrap in Effect).',
    verified: '2025-12-28',
  },
  {
    id: 'linting-stack',
    category: 'standard',
    title: 'SOTA Linting Stack',
    content:
      'Linting: `oxlint` (Type-Aware). ' +
      'Formatting: `biome` (Prettier replacement). ' +
      'AST logic: `ast-grep` (Project scaffolding/refactoring). ' +
      'No ESLint. No Prettier.',
    verified: '2025-12-28',
  },
  {
    id: 'ssot-enforcement',
    category: 'principle',
    title: 'Programmatic SSOT',
    content:
      'Configuration and Standards are enforced programmatically via `config/brain`. ' +
      'Do not document standards in Wiki/README without backing them by active Memory/Rule in Brain. ' +
      'Brain generates LLM prompts (GEMINI.md) to ensure AI alignment.',
    verified: '2025-12-28',
  },
]
