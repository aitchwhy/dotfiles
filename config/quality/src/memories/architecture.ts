import type { Memory } from '../schemas'

export const ARCHITECTURE_MEMORIES: Memory[] = [
  {
    id: 'layer-architecture',
    category: 'pattern',
    title: 'Monorepo Layer Architecture',
    content:
      'Strict unidirectional dependencies (L5 deps on L4 on L3...). ' +
      'L5=Infra, L4=Apps, L3=Auth, L2=Adapters(DB/Storage), L1=Config/UI, L0=Pure(Domain/Schemas). ' +
      'Higher layers depend on lower only.',
    verified: '2025-12-28',
  },
  {
    id: 'layer-rules',
    category: 'constraint',
    title: 'Layer Import Rules',
    content:
      'L0 (Domain) imports NOTHING. L1 imports L0. L2 imports L0, L1. ' +
      'Never import across same-level apps (e.g. api cannot import web). ' +
      'Use shared packages for code sharing.',
    verified: '2025-12-28',
  },
  {
    id: 'domain-purity',
    category: 'principle',
    title: 'Domain is Truth',
    content:
      'packages/domain is the Single Source of Truth. ' +
      'Contains: Branded types, Effect Schemas, HttpApi contracts, Context.Tag interfaces. ' +
      'Zero side effects, zero external adapter dependencies.',
    verified: '2025-12-28',
  },
  {
    id: 'directory-structure',
    category: 'pattern',
    title: 'Directory Structure',
    content:
      'apps/{api,web,agent}, packages/{domain,config,ui,db,auth}, infra/. ' +
      'apps/api/src: handlers (thin), middleware, runtime (AppLive). ' +
      'packages/domain/src: schemas, api, capabilities.',
    verified: '2025-12-28',
  },
]
