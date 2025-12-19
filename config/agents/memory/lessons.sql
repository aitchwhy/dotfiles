-- Active Lessons Dump
-- Generated: 2025-12-19T00:39:54.447Z
-- Count: 10

BEGIN TRANSACTION;

DELETE FROM lessons;

INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (2, '2025-12-12', 'optimization', 'Nix build cache miss problem: Derivation hash includes source code. Split dependencies into separate derivation based on lockfile only.', 'After split, warm builds complete in <60 seconds vs 25+ minutes', 'manual', 2, 1.0000, '2025-12-12');
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
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (3, '2025-12-12', 'pattern', 'Three cache layers for Nix: Cachix (remote), magic-nix-cache (GHA local), Bun cache (useless in sandbox).', 'CI runs dropped from 30+ minutes to 5-10 minutes with proper layer configuration', 'manual', 1, 0.6094, '2025-12-12');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (4, '2025-12-12', 'gotcha', 'Nix sandbox isolation: Package manager caches (~/.bun, ~/.npm) NOT accessible during builds. Use derivation splitting instead.', 'Bun inside Nix derivation cannot see ~/.bun cache', 'manual', 1, 0.6094, '2025-12-12');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (5, '2025-12-12', 'pattern', 'Derivation splitting anti-patterns: bun install in app derivation, using nixos-unstable, missing magic-nix-cache, post-build Cachix push.', 'nix build .#api -v 2>&1 | grep -E "building|cached" shows cached for nodeModules', 'manual', 1, 0.6094, '2025-12-12');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (1, '2025-12-11', 'pattern', 'Architecture switched to Bootloader pattern. Single AGENTS.md routes to modular content.', 'Symlinks verified via readlink ~/.claude/CLAUDE.md', 'manual', 1, 0.5674, '2025-12-11');

COMMIT;
