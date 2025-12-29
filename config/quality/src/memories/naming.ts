import type { Memory } from '../schemas'

export const NAMING_MEMORIES: Memory[] = [
  {
    id: 'file-naming',
    category: 'constraint',
    title: 'File Naming Conventions',
    content:
      'kebab-case only. {name}-machine.ts, {name}.adapter.ts, {name}.test.ts. ' +
      'Route params: $param.tsx. Root: __root.tsx.',
    verified: '2025-12-28',
  },
  {
    id: 'code-naming',
    category: 'constraint',
    title: 'Code Naming Conventions',
    content:
      'PascalCase for Components, Types, Interfaces, Effect Tags (Database). ' +
      'camelCase for functions. SCREAMING_SNAKE for constants.',
    verified: '2025-12-28',
  },
  {
    id: 'effect-naming',
    category: 'constraint',
    title: 'Effect-TS Naming Rules',
    content:
      'Name Context.Tag by Capability (e.g. Database), not implementation. ' +
      'Implementations use Technology prefix (e.g. DrizzleDatabase). ' +
      'BANNED SUFFIXES: *Live, *Port, *Service, *Adapter, *Impl.',
    verified: '2025-12-28',
  },
]
