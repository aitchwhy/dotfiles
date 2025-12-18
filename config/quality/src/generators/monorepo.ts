/**
 * Monorepo Generator
 *
 * Generates pnpm workspaces monorepo structure with:
 * - Root package.json with workspace configuration
 * - pnpm-workspace.yaml for workspace definitions
 * - Shared TypeScript config
 * - Biome linting at root
 * - Shared packages scaffold
 * - Docker Compose for local development
 */
import type { Effect } from 'effect';
import type { FileTree } from '@/layers/file-system';
import { renderTemplates, type TemplateEngine } from '@/layers/template-engine';
import type { ProjectSpec } from '@/schema/project-spec';
import versions from '../../versions.json';

// =============================================================================
// Templates - Root Configuration
// =============================================================================

const PNPM_WORKSPACE_TEMPLATE = `packages:
  - 'packages/*'
  - 'apps/*'
`;

const ROOT_PACKAGE_JSON_TEMPLATE = `{
  "name": "{{name}}",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "workspaces": ["packages/*", "apps/*"],
  "scripts": {
    "dev": "docker compose up",
    "build": "pnpm -r build",
    "test": "vitest",
    "typecheck": "pnpm -r typecheck",
    "lint": "biome check .",
    "lint:fix": "biome check --write .",
    "format": "biome format --write .",
    "validate": "pnpm typecheck && pnpm lint && pnpm test"
  },
  "devDependencies": {
    "@biomejs/biome": "^{{biomeVersion}}",
    "@types/node": "^{{nodeTypesVersion}}",
    "typescript": "^{{typescriptVersion}}",
    "vitest": "^{{vitestVersion}}",
    "tsx": "^{{tsxVersion}}"
  },
  "engines": {
    "node": ">=25.0.0"
  },
  "packageManager": "pnpm@{{pnpmVersion}}"
}`;

const ROOT_TSCONFIG_TEMPLATE = `{
  "extends": "./tsconfig.base.json",
  "compilerOptions": {
    "noEmit": true
  },
  "references": [
    { "path": "./packages/shared" }
  ],
  "include": [],
  "exclude": ["node_modules"]
}`;

const TSCONFIG_BASE_TEMPLATE = `{
  "compilerOptions": {
    "target": "ES2024",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["ES2024"],
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "verbatimModuleSyntax": true,
    "exactOptionalPropertyTypes": true,
    "noUncheckedIndexedAccess": true,
    "noPropertyAccessFromIndexSignature": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "forceConsistentCasingInFileNames": true,
    "declaration": true,
    "declarationMap": true,
    "composite": true
  }
}`;

const BIOME_JSON_TEMPLATE = `{
  "$schema": "https://biomejs.dev/schemas/2.0.0/schema.json",
  "organizeImports": {
    "enabled": true
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "complexity": {
        "noExcessiveCognitiveComplexity": "warn"
      },
      "correctness": {
        "noUnusedImports": "error",
        "noUnusedVariables": "error"
      },
      "style": {
        "noNonNullAssertion": "error",
        "useConst": "error",
        "useImportType": "error"
      },
      "suspicious": {
        "noExplicitAny": "error"
      }
    }
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "single",
      "semicolons": "asNeeded",
      "trailingCommas": "es5"
    }
  },
  "files": {
    "ignore": ["node_modules", "dist", ".next", "coverage"]
  }
}`;

// =============================================================================
// Templates - Shared Package
// =============================================================================

const SHARED_PACKAGE_JSON_TEMPLATE = `{
  "name": "@{{name}}/shared",
  "version": "0.1.0",
  "type": "module",
  "main": "./src/index.ts",
  "types": "./src/index.ts",
  "exports": {
    ".": "./src/index.ts"
  },
  "scripts": {
    "typecheck": "tsc --noEmit",
    "test": "vitest run"
  },
  "dependencies": {
    "zod": "^{{zodVersion}}"
  },
  "devDependencies": {
    "@types/node": "^{{nodeTypesVersion}}",
    "typescript": "^{{typescriptVersion}}",
    "vitest": "^{{vitestVersion}}"
  }
}`;

const SHARED_TSCONFIG_TEMPLATE = `{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules", "dist"]
}`;

const SHARED_INDEX_TS_TEMPLATE = `/**
 * @{{name}}/shared
 *
 * Shared utilities and types for the monorepo.
 */

// Re-export common types
export type Result<T, E = Error> =
  | { readonly ok: true; readonly data: T }
  | { readonly ok: false; readonly error: E }

export const Ok = <T>(data: T): Result<T, never> => ({ ok: true, data })

export const Err = <E>(error: E): Result<never, E> => ({ ok: false, error })
`;

// =============================================================================
// Templates - Infrastructure
// =============================================================================

const GITIGNORE_TEMPLATE = `# Dependencies
node_modules/

# Build outputs
dist/
build/
.next/
.tsbuildinfo

# IDE
.idea/
.vscode/
*.swp
*.swo
.DS_Store

# Testing
coverage/
.playwright/

# Nix
result
result-*

# Logs
*.log
npm-debug.log*

# NOTE: .env files are BLOCKED by PARAGON - use Pulumi ESC
`;

const ENVRC_TEMPLATE = `# Layer 1: Nix Development Shell
use flake

# Layer 2: Pulumi ESC Environment (REQUIRED - fail-fast)
if ! use_esc "{{escOrg}}/{{name}}/dev"; then
  log_error "FATAL: Pulumi ESC environment not available"
  exit 1
fi

# Layer 3: Fail-fast validation (REQUIRED)
: "\${DATABASE_URL:?FATAL: DATABASE_URL not set - check ESC}"

# Add local scripts to PATH
PATH_add ./scripts
PATH_add ./node_modules/.bin

# Minimal logging in multiplexers
if [[ -n "$ZELLIJ" || -n "$TMUX" ]]; then
  export DIRENV_LOG_FORMAT=""
fi

# NO .env.local - ESC is the ONLY source of truth
`;

const FLAKE_NIX_TEMPLATE = `{
  description = "{{name}} - Monorepo";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.\${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # Core
            pnpm
            nodejs_22

            # TypeScript tooling
            typescript
            nodePackages.typescript-language-server

            # Docker
            docker
            docker-compose

            # Utilities
            jq
            fd
            ripgrep
          ];

          shellHook = ''
            echo "{{name}} Development Shell"
            echo "  pnpm install    - Install dependencies"
            echo "  docker compose up - Start all services"
            echo "  pnpm validate   - Run all checks"
          '';
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}`;

const README_TEMPLATE = `# {{name}}

Monorepo powered by pnpm workspaces + Docker Compose.

## Structure

\`\`\`
{{name}}/
├── apps/              # Deployable applications
│   └── ...
├── packages/          # Shared packages
│   └── shared/        # Common utilities and types
├── package.json       # Root workspace config
├── pnpm-workspace.yaml # Workspace definitions
├── docker-compose.yml # Local orchestration
├── Dockerfile         # Container builds
├── tsconfig.json      # TypeScript project references
├── tsconfig.base.json # Shared TypeScript settings
├── biome.json         # Linting and formatting
└── flake.nix          # Nix development shell
\`\`\`

## Getting Started

\`\`\`bash
# Install dependencies
pnpm install

# Start development (via Docker Compose)
docker compose up

# Run all checks
pnpm validate
\`\`\`

## Workspaces

- \`packages/shared\` - Common utilities (@{{name}}/shared)
- \`apps/*\` - Deployable applications

## Scripts

| Command | Description |
|---------|-------------|
| \`docker compose up\` | Start all services |
| \`pnpm build\` | Build all packages |
| \`pnpm test\` | Run all tests (vitest) |
| \`pnpm validate\` | Typecheck + lint + test |

## Configuration

- **Secrets**: Pulumi ESC (see .envrc)
- **Local Dev**: Docker Compose
- **Testing**: Vitest
`;

// =============================================================================
// Generator
// =============================================================================

/**
 * Generate pnpm workspaces monorepo structure
 *
 * Uses versions from versions.json as single source of truth.
 */
export const generateMonorepo = (
  spec: ProjectSpec
): Effect.Effect<FileTree, Error, TemplateEngine> => {
  const npmVersions = versions.npm as Record<string, string>;
  const runtimeVersions = versions.runtime as Record<string, string>;

  const data = {
    name: spec.name,
    description: spec.description,
    escOrg: spec.name,
    zodVersion: npmVersions['zod'],
    typescriptVersion: npmVersions['typescript'],
    biomeVersion: npmVersions['@biomejs/biome'],
    nodeTypesVersion: npmVersions['@types/node'],
    vitestVersion: npmVersions['vitest'],
    tsxVersion: npmVersions['tsx'],
    pnpmVersion: runtimeVersions['pnpm'],
  };

  const templates: FileTree = {
    'package.json': ROOT_PACKAGE_JSON_TEMPLATE,
    'pnpm-workspace.yaml': PNPM_WORKSPACE_TEMPLATE,
    'tsconfig.json': ROOT_TSCONFIG_TEMPLATE,
    'tsconfig.base.json': TSCONFIG_BASE_TEMPLATE,
    'biome.json': BIOME_JSON_TEMPLATE,
    'packages/shared/package.json': SHARED_PACKAGE_JSON_TEMPLATE,
    'packages/shared/tsconfig.json': SHARED_TSCONFIG_TEMPLATE,
    'packages/shared/src/index.ts': SHARED_INDEX_TS_TEMPLATE,
    '.gitignore': GITIGNORE_TEMPLATE,
    '.envrc': ENVRC_TEMPLATE,
    'flake.nix': FLAKE_NIX_TEMPLATE,
    'README.md': README_TEMPLATE,
  };

  return renderTemplates(templates, data);
};
