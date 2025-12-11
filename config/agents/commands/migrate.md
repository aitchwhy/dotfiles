Migrate the current project to STACK compliance.

## Migration Steps

1. Preview changes (always do this first):
```bash
signet migrate --dry-run
```

2. Review the output - it will show:
   - Files that would be deleted (package-lock.json, Dockerfile, etc.)
   - Dependencies that would be removed (express, prisma, etc.)
   - Versions that would be updated (to match STACK.npm)

3. If satisfied, execute migration:
```bash
signet migrate
```

4. Regenerate lockfile:
```bash
bun install
```

5. Verify the migration:
```bash
signet verify
```

## Quick Commands

```bash
# Full migration workflow
signet migrate --dry-run && signet migrate && bun install && signet verify
```

## What Gets Migrated

- **Deleted files**: package-lock.json, yarn.lock, Dockerfile, docker-compose.yml, .eslintrc, .prettierrc, jest.config.js
- **Removed deps**: express, prisma, mysql, dotenv, eslint, prettier, jest, axios, lodash, moment
- **Updated versions**: All dependencies in STACK.npm get pinned to canonical versions

## STACK Authority

Version source of truth: `config/signet/src/stack/versions.ts`
