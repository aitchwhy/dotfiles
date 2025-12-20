-- Active Lessons Dump
-- Generated: 2025-12-20T16:23:52.807Z
-- Count: 19

BEGIN TRANSACTION;

DELETE FROM lessons;

INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (6, '2025-12-18', 'optimization', '1. `9ac4c9de` - Base AWS deployment prompt (Pulumi + Docker workflow)', '1. `9ac4c9de` - Base AWS deployment prompt (Pulumi + Docker workflow)
2. `d1f2cba8` - Fast deployment variant (ECS optimizations for <2min deploys)
3. `4161de9e` - Production-ready prompt (comprehensive with error boundaries, tech debt cleanup)', 'claude', 4, 1.0000, '2025-12-18 15:55:26');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (10, '2025-12-18', 'optimization', 'Now I have clarity. Let me design the implementation plan for:', 'Now I have clarity. Let me design the implementation plan for:
1. Delete Caddyfile (S3+CloudFront is production, Caddy is dead code)
2. Switch to build-time config (remove window.__CONFIG__, use import.meta.env.VITE_*)
3. Add X-Request-ID correlation middleware for backend
4. Optimize ECS/ALB for <2min deploys', 'claude', 8, 1.0000, '2025-12-18 16:55:15');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (11, '2025-12-18', 'optimization', 'The plan aligns with your confirmed requirements:', 'The plan aligns with your confirmed requirements:
- S3+CloudFront is production (Caddyfile is dead code)
- Build-time config (accept separate images per environment)
- X-Request-ID for distributed tracing
- Aggressive deploy optimization', 'claude', 8, 1.0000, '2025-12-18 16:55:15');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (12, '2025-12-18', 'optimization', '1. **Phase 1 (Frontend)**: Delete Caddyfile, switch to build-time `import.meta.env.VITE_*`', '1. **Phase 1 (Frontend)**: Delete Caddyfile, switch to build-time `import.meta.env.VITE_*`
2. **Phase 2 (Backend)**: Just add `exposedHeaders: [''traceparent'', ''tracestate'']` to CORS - no custom middleware needed
3. **Phase 3 (Infra)**: Optimize ECS/ALB for <2min deploys', 'claude', 8, 1.0000, '2025-12-18 16:55:15');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (13, '2025-12-18', 'optimization', '### Phase 3: ECS/ALB Deploy Optimization ✓', '### Phase 3: ECS/ALB Deploy Optimization ✓
- **Modified** `infra/pulumi/src/ecs.ts`:
  - healthCheck.interval: 30 → 10
  - healthCheck.timeout: 5 → 3
  - healthCheck.retries: 3 → 2
  - healthCheck.startPeriod: 60 → 15
  - Added stopTimeout: 30
  - healthCheckGracePeriodSeconds: 120 → 30
- **Modified** `infra/pulumi/src/alb.ts`:
  - interval: 30 → 10
  - deregistrationDelay: 30 → 10', 'claude', 8, 1.0000, '2025-12-18 16:55:15');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (42, '2025-12-20', 'optimization', '1. **Hono references** exist in 7 skills (observability-patterns, typespec-patterns, context7-mcp, mcp-optimization, signet-patterns, hexagonal-architecture, paragon)', '1. **Hono references** exist in 7 skills (observability-patterns, typespec-patterns, context7-mcp, mcp-optimization, signet-patterns, hexagonal-architecture, paragon)', 'claude', 2, 1.0000, '2025-12-20 04:03:33');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (43, '2025-12-20', 'optimization', '| Category | Count | Details |', '| Category | Count | Details |
|----------|-------|---------|
| **Deleted** | 4 | signet.md, signet-patterns/, zod-patterns/, tanstack-patterns/ |
| **Created** | 4 | no-jest.yml, effect-resilience/, api-contract/ (pulumi-esc/ already existed) |
| **Updated** | 12 | paragon, hexagonal, observability, typespec, context7, mcp-optimization, effect-ts-patterns, tdd-patterns, planning-patterns, new-project.md, AGENTS.md, content.ts |', 'claude', 2, 1.0000, '2025-12-20 04:03:33');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (46, '2025-12-20', 'optimization', '1. **Effect Schema Migration** - Replace Zod in 4 hook files', '1. **Effect Schema Migration** - Replace Zod in 4 hook files
2. **Hook Caching** - 5-minute TTL cache for guard results  
3. **SessionStart Consolidation** - Fresh session-init.sh
4. **AST-grep Rules** - 4 new rules for Guards 41-44
5. **settings.json** - bun invocation + reduced timeouts
6. **Progressive Disclosure** - Split 7 skills into core + references/', 'claude', 2, 1.0000, '2025-12-20 05:13:10');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (47, '2025-12-20', 'optimization', 'Thank you for the corrected plan. This is much more principled:', 'Thank you for the corrected plan. This is much more principled:
- Zero try/catch with full Effect pipelines
- Delete instead of deprecate (no "keep for reference")
- No caching layer (premature optimization)
- Audit skills before splitting (delete unused first)
- Measure before optimizing timeouts', 'claude', 2, 1.0000, '2025-12-20 05:13:10');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (48, '2025-12-20', 'optimization', '- **Zero try/catch** with full Effect pipelines', '- **Zero try/catch** with full Effect pipelines
- **Delete, don''t deprecate** (session-start.sh will be deleted, not kept for reference)
- **No caching layer** (removed as premature optimization)
- **Audit before splitting** (typespec-patterns, refactoring-catalog marked for deletion)
- **Evidence-based timeouts** (measure p99 first, then set 3× that value)', 'claude', 2, 1.0000, '2025-12-20 05:13:10');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (49, '2025-12-20', 'optimization', 'Phase 4: settings.json Optimization. First, measure hook latency:', 'Phase 4: settings.json Optimization. First, measure hook latency:', 'claude', 2, 1.0000, '2025-12-20 05:13:10');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (50, '2025-12-20', 'optimization', 'Skills over 250 lines:', 'Skills over 250 lines:
- state-machine-patterns: 529
- paragon: 464
- nix-infrastructure: 405
- hexagonal-architecture: 397
- secrets-management: 353
- nix-build-optimization: 347
- observability-patterns: 341
- semantic-codebase: 316
- parse-boundary-patterns: 280
- planning-patterns: 267
- devops-patterns: 263', 'claude', 2, 1.0000, '2025-12-20 05:13:10');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (51, '2025-12-20', 'optimization', 'All 5 phases complete. Summary of the optimization:', 'All 5 phases complete. Summary of the optimization:', 'claude', 2, 1.0000, '2025-12-20 05:13:10');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (52, '2025-12-20', 'optimization', '## Phase 4: settings.json Optimization', '## Phase 4: settings.json Optimization
- Switched all hook invocations from `node --import tsx` to `bun`
- Evidence-based timeout: 2s (measured 88ms p99, 3× with 2s minimum)', 'claude', 2, 1.0000, '2025-12-20 05:13:10');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (2, '2025-12-12', 'optimization', 'Nix build cache miss problem: Derivation hash includes source code. Split dependencies into separate derivation based on lockfile only.', 'After split, warm builds complete in <60 seconds vs 25+ minutes', 'manual', 2, 0.9106, '2025-12-12');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (3, '2025-12-12', 'pattern', 'Three cache layers for Nix: Cachix (remote), magic-nix-cache (GHA local), Bun cache (useless in sandbox).', 'CI runs dropped from 30+ minutes to 5-10 minutes with proper layer configuration', 'manual', 1, 0.5378, '2025-12-12');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (4, '2025-12-12', 'gotcha', 'Nix sandbox isolation: Package manager caches (~/.bun, ~/.npm) NOT accessible during builds. Use derivation splitting instead.', 'Bun inside Nix derivation cannot see ~/.bun cache', 'manual', 1, 0.5378, '2025-12-12');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (5, '2025-12-12', 'pattern', 'Derivation splitting anti-patterns: bun install in app derivation, using nixos-unstable, missing magic-nix-cache, post-build Cachix push.', 'nix build .#api -v 2>&1 | grep -E "building|cached" shows cached for nodeModules', 'manual', 1, 0.5378, '2025-12-12');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (1, '2025-12-11', 'pattern', 'Architecture switched to Bootloader pattern. Single AGENTS.md routes to modular content.', 'Symlinks verified via readlink ~/.claude/CLAUDE.md', 'manual', 1, 0.5007, '2025-12-11');

COMMIT;
