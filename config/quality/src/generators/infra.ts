/**
 * Infrastructure Generator
 *
 * Generates infrastructure-as-code with:
 * - docker-compose.yml for local development
 * - Dockerfile for containerized builds
 * - Pulumi TypeScript project for cloud infrastructure (version-aware)
 * - VSCode/Neovim debug configurations
 *
 * Uses STACK from @/stack for version-aware generation.
 */
import type { Effect } from 'effect';
import type { FileTree } from '@/layers/file-system';
import { renderTemplates, type TemplateEngine } from '@/layers/template-engine';
import type { ProjectSpec } from '@/schema/project-spec';
import { STACK } from '@/stack';

// =============================================================================
// Templates - Docker Compose
// =============================================================================

const DOCKER_COMPOSE_TEMPLATE = `# {{name}} - Local Development Orchestrator
# Start with: docker compose up

services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "\${PORT:-3000}:3000"
    environment:
      - NODE_ENV=development
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - ./apps/api:/app/apps/api
      - /app/node_modules
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 10s
      timeout: 5s
      retries: 3

  web:
    build:
      context: .
      dockerfile: Dockerfile
      target: web
    ports:
      - "5173:5173"
    environment:
      - NODE_ENV=development
      - VITE_API_URL=http://localhost:3000
    depends_on:
      api:
        condition: service_healthy
    volumes:
      - ./apps/web:/app/apps/web
      - /app/node_modules

  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: {{name}}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
`;

const DOCKERFILE_TEMPLATE = `# Stage 1: Base with pnpm
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

# Stage 4: Runtime (API)
FROM base AS api
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY package.json ./
EXPOSE 3000
CMD ["node", "dist/index.js"]

# Stage 5: Web (dev server)
FROM base AS web
WORKDIR /app
ENV NODE_ENV=development
COPY --from=deps /app/node_modules ./node_modules
COPY . .
EXPOSE 5173
CMD ["pnpm", "run", "dev", "--host"]
`;

const DOCKERIGNORE_TEMPLATE = `node_modules
dist
.git
.env
.env.*
*.log
.DS_Store
coverage
.nyc_output
`;

// =============================================================================
// Templates - Debug Configurations
// =============================================================================

const VSCODE_LAUNCH_TEMPLATE = `{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Debug Current File",
      "runtimeExecutable": "pnpm",
      "runtimeArgs": ["exec", "tsx"],
      "args": ["\${file}"],
      "cwd": "\${workspaceFolder}",
      "skipFiles": ["<node_internals>/**"]
    },
    {
      "type": "node",
      "request": "launch",
      "name": "Debug API",
      "runtimeExecutable": "pnpm",
      "runtimeArgs": ["exec", "tsx"],
      "args": ["\${workspaceFolder}/apps/api/src/index.ts"],
      "cwd": "\${workspaceFolder}/apps/api",
      "env": {
        "NODE_ENV": "development"
      },
      "skipFiles": ["<node_internals>/**"]
    },
    {
      "type": "node",
      "request": "launch",
      "name": "Debug Tests",
      "runtimeExecutable": "pnpm",
      "runtimeArgs": ["exec", "vitest", "run", "\${file}"],
      "cwd": "\${workspaceFolder}",
      "skipFiles": ["<node_internals>/**"]
    },
    {
      "type": "node",
      "request": "attach",
      "name": "Attach to Process",
      "port": 9229,
      "skipFiles": ["<node_internals>/**"]
    }
  ],
  "compounds": [
    {
      "name": "Debug Full Stack",
      "configurations": ["Debug API"],
      "stopAll": true
    }
  ]
}`;

const NVIM_DAP_TEMPLATE = `-- {{name}} DAP Configuration
-- Load with: require('.nvim.dap')

local dap = require('dap')

-- Node.js adapter (via vscode-js-debug)
dap.adapters['pwa-node'] = {
  type = 'server',
  host = '127.0.0.1',
  port = 9229,
}

-- Configurations
dap.configurations.typescript = {
  {
    type = 'pwa-node',
    request = 'launch',
    name = 'Debug Current File',
    runtimeExecutable = 'pnpm',
    runtimeArgs = { 'exec', 'tsx' },
    args = { '\${file}' },
    cwd = '\${workspaceFolder}',
    sourceMaps = true,
  },
  {
    type = 'pwa-node',
    request = 'launch',
    name = 'Debug API',
    runtimeExecutable = 'pnpm',
    runtimeArgs = { 'exec', 'tsx' },
    args = { '\${workspaceFolder}/apps/api/src/index.ts' },
    cwd = '\${workspaceFolder}/apps/api',
    env = {
      NODE_ENV = 'development',
    },
    sourceMaps = true,
  },
  {
    type = 'pwa-node',
    request = 'attach',
    name = 'Attach to Process',
    port = 9229,
    sourceMaps = true,
  },
}

-- Also apply to JavaScript
dap.configurations.javascript = dap.configurations.typescript
`;

// =============================================================================
// Templates - Pulumi
// =============================================================================

const PULUMI_YAML_TEMPLATE = `name: {{name}}
runtime:
  name: nodejs
  options:
    typescript: true
description: {{name}} infrastructure
`;

const PULUMI_DEV_YAML_TEMPLATE = `config:
  {{name}}:environment: dev
`;

const PULUMI_INDEX_TEMPLATE = `/**
 * {{name}} - Infrastructure as Code
 *
 * Pulumi TypeScript infrastructure definitions.
 * Generated by Signet with STACK version ${STACK.meta.ssotVersion}
 *
 * See: https://www.pulumi.com/docs/
 */
import * as pulumi from '@pulumi/pulumi'
import * as aws from '@pulumi/aws'
import * as awsx from '@pulumi/awsx'

// Configuration
const config = new pulumi.Config()
const environment = config.require('environment') as 'dev' | 'staging' | 'prod'
const region = config.get('region') ?? 'us-east-1'

// Tags for all resources
const tags = {
  Environment: environment,
  ManagedBy: 'signet',
  StackVersion: '${STACK.meta.ssotVersion}',
}

// Export stack outputs
export const env = environment
export const stackName = pulumi.getStack()
export const awsRegion = region

// =============================================================================
// Infrastructure Resources
// =============================================================================

// Example: App Runner Service
// Uncomment and configure as needed:
//
// const appRunner = new aws.apprunner.Service('api', {
//   serviceName: \`{{name}}-api-\${environment}\`,
//   sourceConfiguration: {
//     imageRepository: {
//       imageIdentifier: \`\${process.env.AWS_ACCOUNT_ID}.dkr.ecr.\${region}.amazonaws.com/{{name}}-api:latest\`,
//       imageRepositoryType: 'ECR',
//       imageConfiguration: {
//         port: '3000',
//         runtimeEnvironmentVariables: {
//           NODE_ENV: environment === 'prod' ? 'production' : 'development',
//         },
//       },
//     },
//     autoDeploymentsEnabled: true,
//   },
//   instanceConfiguration: {
//     cpu: '1024',
//     memory: '2048',
//   },
//   tags,
// })
//
// export const apiUrl = appRunner.serviceUrl
`;

// Pulumi package.json generated from STACK versions
const PULUMI_PACKAGE_JSON_TEMPLATE = `{
  "name": "{{name}}-infra",
  "version": "0.1.0",
  "type": "module",
  "main": "index.ts",
  "scripts": {
    "preview": "pulumi preview",
    "up": "pulumi up",
    "destroy": "pulumi destroy",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "@pulumi/pulumi": "${STACK.npm['@pulumi/pulumi']}",
    "@pulumi/aws": "${STACK.npm['@pulumi/aws']}",
    "@pulumi/awsx": "${STACK.npm['@pulumi/awsx']}",
    "@pulumi/random": "${STACK.npm['@pulumi/random']}"
  },
  "devDependencies": {
    "@types/node": "22.0.0",
    "typescript": "${STACK.npm.typescript}"
  }
}`;

const PULUMI_TSCONFIG_TEMPLATE = `{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["ES2022"],
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "outDir": "./bin"
  },
  "include": ["*.ts"],
  "exclude": ["node_modules"]
}`;

// =============================================================================
// Generator
// =============================================================================

/**
 * Generate infrastructure files (Pulumi + Docker Compose + debug config)
 */
export const generateInfra = (
  spec: ProjectSpec
): Effect.Effect<FileTree, Error, TemplateEngine> => {
  const data = {
    name: spec.name,
    description: spec.description,
    isVscode: spec.observability.debugger === 'vscode',
    isNvimDap: spec.observability.debugger === 'nvim-dap',
  };

  // Base templates
  const templates: FileTree = {
    // Docker (local orchestration)
    'docker-compose.yml': DOCKER_COMPOSE_TEMPLATE,
    Dockerfile: DOCKERFILE_TEMPLATE,
    '.dockerignore': DOCKERIGNORE_TEMPLATE,

    // Pulumi (cloud infrastructure)
    'infra/Pulumi.yaml': PULUMI_YAML_TEMPLATE,
    'infra/Pulumi.dev.yaml': PULUMI_DEV_YAML_TEMPLATE,
    'infra/index.ts': PULUMI_INDEX_TEMPLATE,
    'infra/package.json': PULUMI_PACKAGE_JSON_TEMPLATE,
    'infra/tsconfig.json': PULUMI_TSCONFIG_TEMPLATE,
  };

  // Conditional: Debug configuration based on editor
  if (spec.observability.debugger === 'vscode') {
    templates['.vscode/launch.json'] = VSCODE_LAUNCH_TEMPLATE;
  } else if (spec.observability.debugger === 'nvim-dap') {
    templates['.nvim/dap.lua'] = NVIM_DAP_TEMPLATE;
  }

  return renderTemplates(templates, data);
};
