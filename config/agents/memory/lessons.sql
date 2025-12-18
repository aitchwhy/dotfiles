-- Active Lessons Dump
-- Generated: 2025-12-18T16:20:18.526Z
-- Count: 6

BEGIN TRANSACTION;

DELETE FROM lessons;

INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (2, '2025-12-12', 'optimization', 'Nix build cache miss problem: Derivation hash includes source code. Split dependencies into separate derivation based on lockfile only.', 'After split, warm builds complete in <60 seconds vs 25+ minutes', 'manual', 2, 1.0000, '2025-12-12');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (6, '2025-12-18', 'optimization', '1. `9ac4c9de` - Base AWS deployment prompt (Pulumi + Docker workflow)', '1. `9ac4c9de` - Base AWS deployment prompt (Pulumi + Docker workflow)
2. `d1f2cba8` - Fast deployment variant (ECS optimizations for <2min deploys)
3. `4161de9e` - Production-ready prompt (comprehensive with error boundaries, tech debt cleanup)', 'claude', 4, 1.0000, '2025-12-18 15:55:26');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (3, '2025-12-12', 'pattern', 'Three cache layers for Nix: Cachix (remote), magic-nix-cache (GHA local), Bun cache (useless in sandbox).', 'CI runs dropped from 30+ minutes to 5-10 minutes with proper layer configuration', 'manual', 1, 0.6213, '2025-12-12');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (4, '2025-12-12', 'gotcha', 'Nix sandbox isolation: Package manager caches (~/.bun, ~/.npm) NOT accessible during builds. Use derivation splitting instead.', 'Bun inside Nix derivation cannot see ~/.bun cache', 'manual', 1, 0.6213, '2025-12-12');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (5, '2025-12-12', 'pattern', 'Derivation splitting anti-patterns: bun install in app derivation, using nixos-unstable, missing magic-nix-cache, post-build Cachix push.', 'nix build .#api -v 2>&1 | grep -E "building|cached" shows cached for nodeModules', 'manual', 1, 0.6213, '2025-12-12');
INSERT INTO lessons (id, date, category, lesson, evidence, source, occurrence_count, decay_score, created_at) VALUES (1, '2025-12-11', 'pattern', 'Architecture switched to Bootloader pattern. Single AGENTS.md routes to modular content.', 'Symlinks verified via readlink ~/.claude/CLAUDE.md', 'manual', 1, 0.5785, '2025-12-11');

COMMIT;
