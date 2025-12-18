---
name: devops-patterns
description: Docker-first DevOps - Docker Compose for local dev, Vitest for testing, Pulumi ESC for secrets.
allowed-tools: Read, Write, Edit, Bash
token-budget: 1000
---

# Docker-First DevOps

## Core Philosophy

```
localhost === CI === production
```

Achieved via:
- **Docker Compose**: Local service orchestration
- **pnpm**: Fast, disk-efficient package manager
- **Vitest**: Fast TypeScript-native testing
- **Pulumi ESC**: Secrets and configuration (fail-fast)

## The Stack

| Layer | Tool | Anti-Pattern |
|-------|------|--------------|
| Local Dev | `docker compose` | `process-compose`, `bun run dev` |
| Package Manager | `pnpm` | `bun`, `npm`, `yarn` |
| Testing | `vitest` | `bun test`, `jest` |
| Containers | `Dockerfile` | `nix2container` |
| Secrets | `Pulumi ESC` | `.env` files, hardcoded |

## Blocked Files (enforced by hook)

These files trigger a BLOCK in Claude Code:
- `process-compose.yaml` / `process-compose.yml`
- `bun.lock` / `bun.lockb`
- `.env` (use Pulumi ESC instead)

## Blocked Commands (enforced by hook)

These commands trigger a BLOCK in Claude Code:
- `process-compose up|start`
- `bun run|test|install`
- `npm|yarn run dev|start|serve`

## Correct Patterns

### Local Development

Always start services via Docker Compose:

```bash
# Start all services
docker compose up -d

# Start specific service
docker compose up -d api

# Or use just alias
just dev
```

### docker-compose.yml Structure

```yaml
services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "${PORT:-8787}:8787"
    environment:
      - NODE_ENV=development
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - ./apps/api:/app/apps/api
      - /app/node_modules
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8787/health"]
      interval: 10s
      timeout: 5s
      retries: 3

  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: app
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5
    volumes:
      - db-data:/var/lib/postgresql/data

  worker:
    build: .
    command: pnpm run worker
    depends_on:
      - api

volumes:
  db-data:
```

### Dockerfile Pattern (Multi-stage)

```dockerfile
# Stage 1: Base with pnpm
FROM node:22-slim AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

# Stage 2: Dependencies
FROM base AS deps
WORKDIR /app
COPY pnpm-lock.yaml package.json ./
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile

# Stage 3: Builder
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN pnpm build

# Stage 4: Runtime
FROM base AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY package.json ./
EXPOSE 8787
CMD ["node", "dist/index.js"]
```

### Testing with Vitest

```bash
# Run all tests
pnpm test

# Watch mode
vitest --watch

# With coverage
vitest --coverage

# Run specific test file
vitest run src/api.test.ts
```

### Pulumi ESC Integration

**Required .envrc pattern (fail-fast):**

```bash
# Layer 1: Nix dev shell
use flake

# Layer 2: Pulumi ESC (REQUIRED - fail-fast)
if ! use_esc "org/project/dev"; then
  log_error "FATAL: Pulumi ESC environment not available"
  exit 1
fi

# Layer 3: Fail-fast validation
: "${DATABASE_URL:?FATAL: DATABASE_URL not set - check ESC}"
: "${API_KEY:?FATAL: API_KEY not set - check ESC}"

# NO .env.local - ESC is source of truth
```

### GitHub Actions Workflow

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup pnpm
        uses: pnpm/action-setup@v4
        with:
          version: 9

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'pnpm'

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Typecheck
        run: pnpm run typecheck

      - name: Lint
        run: pnpm run lint

      - name: Test
        run: pnpm test

      - name: Build
        run: pnpm build

      - name: Build Docker image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: false
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

## Decision Tree

| Question | Answer |
|----------|--------|
| Start API locally? | `docker compose up api` |
| Run all services? | `docker compose up` or `just dev` |
| Build image? | `docker build -t api .` |
| Run tests? | `pnpm test` or `vitest` |
| Deploy? | Push to main, GHA builds & pushes |

## Why Docker-First?

1. **Universal knowledge**: Docker is industry standard
2. **Fast iteration**: Volume mounts for hot reload
3. **Clear debugging**: Dockerfile layers are explicit
4. **CI/CD simplicity**: Native Docker support everywhere
5. **Environment parity**: Same containers locally and in prod

## Related Skills

- `pulumi-esc`: Secrets and configuration management
- `hexagonal-architecture`: No-mock testing with real services
- `typescript-patterns`: TypeScript best practices
