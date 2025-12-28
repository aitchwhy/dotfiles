import type { SkillDefinition } from '../schemas'
import { SkillName } from '../schemas'

export const devopsPatternsSkill: SkillDefinition = {
  frontmatter: {
    name: SkillName('devops-patterns'),
    description:
      'Docker-first DevOps - Docker Compose for local dev, Vitest for testing, Pulumi ESC for secrets.',
    allowedTools: ['Read', 'Write', 'Edit', 'Bash'],
    tokenBudget: 1200,
  },
  sections: [
    {
      heading: 'Overview',
      content: `# Docker-First DevOps`,
    },
    {
      heading: 'Stack Versions (December 2025)',
      content: `| Tool | Version | Notes |
|------|---------|-------|
| Node.js | 24 | Current (not LTS 22) |
| pnpm | 10.x | Required package manager |
| PostgreSQL | 18 | Latest major |
| TypeScript | 5.8+ | Project references |`,
    },
    {
      heading: 'Core Philosophy',
      content: `\`\`\`
localhost === CI === production
\`\`\`

Achieved via:
- **Docker Compose**: Local service orchestration
- **pnpm**: Fast, disk-efficient package manager
- **Vitest**: Fast TypeScript-native testing
- **Pulumi ESC**: Secrets and configuration (fail-fast)`,
    },
    {
      heading: 'The Stack',
      content: `| Layer | Tool | Anti-Pattern |
|-------|------|--------------|
| Local Dev | \`docker compose\` | \`process-compose\`, \`bun run dev\` |
| Package Manager | \`pnpm\` | \`bun\`, \`npm\`, \`yarn\` |
| Testing | \`vitest\` | \`bun test\`, \`jest\` |
| Containers | \`Dockerfile\` | \`nix2container\` |
| Secrets | \`Pulumi ESC\` | \`.env\` files, hardcoded |`,
    },
    {
      heading: 'Blocked Files (enforced by hook)',
      content: `These files trigger a BLOCK in Claude Code:
- \`process-compose.yaml\` / \`process-compose.yml\`
- \`bun.lock\` / \`bun.lockb\`
- \`.env\` (use Pulumi ESC instead)`,
    },
    {
      heading: 'Blocked Commands (enforced by hook)',
      content: `These commands trigger a BLOCK in Claude Code:
- \`process-compose up|start\`
- \`bun run|test|install\`
- \`npm|yarn run dev|start|serve\``,
    },
    {
      heading: 'Correct Patterns',
      content: `### Local Development

Always start services via Docker Compose:

\`\`\`bash
# Start all services
docker compose up -d

# Start specific service
docker compose up -d api

# Or use just alias
just dev
\`\`\`

### docker-compose.yml Structure

\`\`\`yaml
services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "\${PORT:-8787}:8787"
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
\`\`\`

### Dockerfile Pattern (Multi-stage)

\`\`\`dockerfile
# Stage 1: Base with pnpm
FROM node:24-slim AS base
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
\`\`\`

### Testing with Vitest

\`\`\`bash
# Run all tests
pnpm test

# Watch mode
vitest --watch

# With coverage
vitest --coverage

# Run specific test file
vitest run src/api.test.ts
\`\`\`

### Pulumi ESC Integration

**Required .envrc pattern (fail-fast):**

\`\`\`bash
# Layer 1: Nix dev shell
use flake

# Layer 2: Pulumi ESC (REQUIRED - fail-fast)
if ! use_esc "org/project/dev"; then
  log_error "FATAL: Pulumi ESC environment not available"
  exit 1
fi

# Layer 3: Fail-fast validation
: "\${DATABASE_URL:?FATAL: DATABASE_URL not set - check ESC}"
: "\${API_KEY:?FATAL: API_KEY not set - check ESC}"

# NO .env.local - ESC is source of truth
\`\`\`

### GitHub Actions Workflow (Hybrid OIDC Pattern)

\`\`\`yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

permissions:
  contents: read
  id-token: write  # Required for OIDC

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '24'
          cache: 'pnpm'

      - run: pnpm install --frozen-lockfile

      - run: pnpm test

      # AWS auth via GitHub OIDC (runner identity)
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::\${{ vars.AWS_ACCOUNT_ID }}:role/github-actions
          aws-region: us-east-1

      # Config from ESC (pulumi-stacks provides infra values)
      - uses: pulumi/auth-actions@v1
        with:
          organization: myorg
          requested-token-type: urn:pulumi:token-type:access_token:organization

      - uses: pulumi/esc-action@v1
        with:
          environment: myorg/myproject/staging

      # Build with ECR URL from ESC
      - uses: docker/build-push-action@v6
        with:
          push: true
          tags: \${{ env.ECR_REPOSITORY_URL }}:\${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
\`\`\`

**Hybrid OIDC explained:**
- \`aws-actions/configure-aws-credentials\`: GitHub OIDC -> AWS (runner identity)
- \`pulumi/esc-action\`: ESC -> Config values (pulumi-stacks for infra outputs)
- Never use \`curl | sh\` for Pulumi in CI`,
    },
    {
      heading: 'Decision Tree',
      content: `| Question | Answer |
|----------|--------|
| Start API locally? | \`docker compose up api\` |
| Run all services? | \`docker compose up\` or \`just dev\` |
| Build image? | \`docker build -t api .\` |
| Run tests? | \`pnpm test\` or \`vitest\` |
| Deploy? | Push to main, GHA builds & pushes |`,
    },
    {
      heading: 'Pulumi ESC 4-Layer Hierarchy',
      content: `Configuration imports from most abstract to most specific:

| Layer | File | Purpose | Example |
|-------|------|---------|---------|
| 1 | \`vendor.yaml\` | External service configs | Twilio, Hume, OpenAI |
| 2 | \`infra-shared.yaml\` | Shared infra outputs | ECR URLs, RDS endpoints |
| 3 | \`base.yaml\` | Constants | Ports, regions, defaults |
| 4 | \`{env}.yaml\` | Environment-specific | dev, staging, prod |

\`\`\`yaml
# staging.yaml
imports:
  - org/project/base
  - org/project/infra-shared
  - org/project/vendor
values:
  environment: staging
\`\`\``,
    },
    {
      heading: 'Explicitly Replaces',
      content: `| Deprecated | Replacement | Reason |
|------------|-------------|--------|
| process-compose | Docker Compose | Industry standard |
| nix2container | Multi-stage Dockerfile | Clear, portable |
| devenv.sh | Docker Compose | Simpler, universal |
| .env files | Pulumi ESC | No file drift |
| Bun runtime | Node.js 24 | Node.js parity |`,
    },
    {
      heading: 'Why Docker-First?',
      content: `1. **Universal knowledge**: Docker is industry standard
2. **Fast iteration**: Volume mounts for hot reload
3. **Clear debugging**: Dockerfile layers are explicit
4. **CI/CD simplicity**: Native Docker support everywhere
5. **Environment parity**: Same containers locally and in prod`,
    },
    {
      heading: 'Related Skills',
      content: `- \`pulumi-esc\`: Secrets and configuration management
- \`hexagonal-architecture\`: No-mock testing with real services
- \`typescript-patterns\`: TypeScript best practices`,
    },
  ],
}
