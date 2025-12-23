-- Active Lessons Dump
-- Generated: 2025-12-23T20:32:57.682Z
-- Count: 33

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
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (60, '2025-12-21', 'optimization', '| Item | Status | Files |', '| Item | Status | Files |
|------|--------|-------|
| Nix skills | 4 found | nix-patterns, nix-build-optimization, nix-infrastructure, nix-configuration-centralization |
| process-compose refs | ~20 found | nix-infrastructure skill, lib/ports.nix, devops-patterns, aliases |
| nix2container refs | ~10 found | nix-build-optimization, AGENTS.md, verify script |
| SessionStart hooks | GOOD in settings.json | Only session-init.sh |
| secrets-audit.ts | EXISTS (6.7k) | Needs absorption into paragon-gu', 'claude', 2, 1.0000, '2025-12-21 02:30:28');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (61, '2025-12-21', 'optimization', '**Key actions:**', '**Key actions:**
1. **DELETE** nix-infrastructure and nix-build-optimization skills
2. **KEEP** nix-patterns (with scope note) and nix-configuration-centralization
3. **SYMLINK** settings.json via nix-darwin (not copy)
4. **ABSORB** secrets-audit.ts into paragon-guard.ts, then delete
5. **PURGE** all process-compose references (~20 files)
6. **ONE hook per event** (no multiple SessionStart entries)', 'claude', 2, 1.0000, '2025-12-21 02:30:28');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (62, '2025-12-21', 'optimization', '**Nix Scope Enforcement:**', '**Nix Scope Enforcement:**
- Deleted `nix-infrastructure` and `nix-build-optimization` skills
- Updated `nix-patterns/SKILL.md` with scope restriction (dotfiles only)
- Updated `AGENTS.md` with new Nix skills section', 'claude', 2, 1.0000, '2025-12-21 02:30:28');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (63, '2025-12-21', 'optimization', '**Verification Results:**', '**Verification Results:**
```
✓ nix-infrastructure deleted
✓ nix-build-optimization deleted
✓ Symlink exists
✓ No claude-code.json
✓ secrets-audit.ts deleted
✓ paragon-guard has secrets
```', 'claude', 2, 1.0000, '2025-12-21 02:30:28');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (69, '2025-12-22', 'optimization', 'Now let me fix the skills files. First the MCP optimization skill:', 'Now let me fix the skills files. First the MCP optimization skill:', 'claude', 2, 1.0000, '2025-12-22 03:00:16');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (70, '2025-12-22', 'gotcha', '**Nix Sandbox Gotcha**: The quality-typecheck fix highlights that Nix builds run in a read-only sandbox. Any tool that needs to write (like `bun install`) must copy sources to `$TMPDIR` first.', '**Nix Sandbox Gotcha**: The quality-typecheck fix highlights that Nix builds run in a read-only sandbox. Any tool that needs to write (like `bun install`) must copy sources to `$TMPDIR` first.
`─────────────────────────────────────────────────`', 'claude', 2, 1.0000, '2025-12-22 03:00:16');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (71, '2025-12-22', 'optimization', '**Files updated** (Signet → Quality System):', '**Files updated** (Signet → Quality System):
- `config/quality/src/stack/versions.ts`
- `config/quality/src/hooks/enforce-versions.ts`
- `config/agents/skills/{mcp-optimization,nix-configuration-centralization,semantic-codebase}/SKILL.md`
- `config/agents/hooks/{lib/types.ts,enforce-versions.ts}`
- `config/agents/{README.md,evolution/grade.sh}`
- `justfile`, `.github/workflows/validate.yml`', 'claude', 2, 1.0000, '2025-12-22 03:00:16');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (75, '2025-12-22', 'bug', 'Version 26 exists. The error was a race condition. Let me refresh the state and try again:', 'Version 26 exists. The error was a race condition. Let me refresh the state and try again:', 'claude', 2, 1.0000, '2025-12-22 14:51:26');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (77, '2025-12-23', 'bug', '`★ Insight ─────────────────────────────────────`', '`★ Insight ─────────────────────────────────────`
**Why this fix works**: When Pulumi creates a task definition with `imageUri: ember:sha-abc123`, ECS stores that exact digest. On the next deploy with `sha-xyz789`, Pulumi creates a **new task definition revision** which forces ECS to pull the new image. The `:latest` tag problem was that Pulumi reused the same task definition (since `:latest` is the same string), so ECS never knew to pull a new image.
`───────────────────────────────────────────', 'claude', 2, 1.0000, '2025-12-23 02:14:32');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (79, '2025-12-23', 'optimization', '`★ Insight ─────────────────────────────────────`', '`★ Insight ─────────────────────────────────────`
**MCP Server Selection Strategy**:
- Your current 9 servers are well-aligned with general development needs
- Adding 4 stack-specific servers creates a comprehensive toolkit:
  - **jsrepo** → Component registry (shadcn patterns)
  - **docker** → Docker Compose workflows (matches your dev setup)
  - **postgres** → Query optimization for Drizzle/PG
  - **shadcn** → React 19 + Tailwind 4.x component access', 'claude', 8, 1.0000, '2025-12-23 18:57:59');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (80, '2025-12-23', 'optimization', '| New Server | Package | Purpose |', '| New Server | Package | Purpose |
|------------|---------|---------|
| jsrepo | `@jsrepo/mcp` | Component registries |
| docker | `mcp-server-docker` | Container management |
| postgres | `postgres-mcp` | PostgreSQL optimization |
| shadcn | `shadcn-ui-mcp` | React/Tailwind components |', 'claude', 8, 1.0000, '2025-12-23 18:57:59');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (81, '2025-12-23', 'optimization', 'The new tools will be available in your next Claude Code or Claude Desktop session. You can now use:', 'The new tools will be available in your next Claude Code or Claude Desktop session. You can now use:
- **jsrepo tools**: Search registries, browse components, add code blocks
- **docker tools**: Manage containers, compose stacks
- **postgres tools**: Query optimization, index tuning, health checks
- **shadcn tools**: React component docs, installation', 'claude', 8, 1.0000, '2025-12-23 18:57:59');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (88, '2025-12-23', 'optimization', '| Server | Package | Value for Your Stack |', '| Server | Package | Value for Your Stack |
|--------|---------|---------------------|
| **PostgreSQL** | `@modelcontextprotocol/server-postgres` | Query execution, schema inspection |
| **Brave Search** | `@anthropic/mcp-server-brave-search` | Web search alternative to fetch |
| **Tavily** | `tavily-mcp` | AI-optimized web research |
| **mem0** | `mem0-mcp` | Persistent AI memory across sessions |
| **SonarQube** | `sonarqube-mcp-server` | Code quality analysis |', 'claude', 6, 1.0000, '2025-12-23 19:10:50');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (68, '2025-12-21', 'optimization', '**dotfiles (10 commits):**', '**dotfiles (10 commits):**
```
5e21b3d docs(agents): update nix skills section for dotfiles-only scope
ddc5a66 docs(skills): update hexagonal-architecture to use docker compose
b4de066 docs(skills): update devops-patterns with node 24 and esc hierarchy
e1477d2 chore(cleanup): purge process-compose references
023d36a chore(cleanup): delete redundant secrets-audit.ts and claude-code.json
b4717a9 feat(paragon): absorb secrets detection into guard 32
8158893 chore(settings): consolidate hooks with p', 'claude', 1, 0.8379, '2025-12-21 02:33:07');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (2, '2025-12-12', 'optimization', 'Nix build cache miss problem: Derivation hash includes source code. Split dependencies into separate derivation based on lockfile only.', 'After split, warm builds complete in <60 seconds vs 25+ minutes', 'manual', 2, 0.7294, '2025-12-12');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (3, '2025-12-12', 'pattern', 'Three cache layers for Nix: Cachix (remote), magic-nix-cache (GHA local), Bun cache (useless in sandbox).', 'CI runs dropped from 30+ minutes to 5-10 minutes with proper layer configuration', 'manual', 1, 0.4308, '2025-12-12');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (4, '2025-12-12', 'gotcha', 'Nix sandbox isolation: Package manager caches (~/.bun, ~/.npm) NOT accessible during builds. Use derivation splitting instead.', 'Bun inside Nix derivation cannot see ~/.bun cache', 'manual', 1, 0.4308, '2025-12-12');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (5, '2025-12-12', 'pattern', 'Derivation splitting anti-patterns: bun install in app derivation, using nixos-unstable, missing magic-nix-cache, post-build Cachix push.', 'nix build .#api -v 2>&1 | grep -E "building|cached" shows cached for nodeModules', 'manual', 1, 0.4308, '2025-12-12');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (1, '2025-12-11', 'pattern', 'Architecture switched to Bootloader pattern. Single AGENTS.md routes to modular content.', 'Symlinks verified via readlink ~/.claude/CLAUDE.md', 'manual', 1, 0.4011, '2025-12-11');

COMMIT;
