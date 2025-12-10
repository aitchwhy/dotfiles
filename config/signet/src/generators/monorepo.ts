/**
 * Monorepo Generator
 *
 * Generates Bun workspaces monorepo structure with:
 * - Root package.json with workspace configuration
 * - Shared TypeScript config
 * - Biome linting at root
 * - Shared packages scaffold
 */
import type { Effect } from 'effect';
import type { FileTree } from '@/layers/file-system';
import { renderTemplates, type TemplateEngine } from '@/layers/template-engine';
import type { ProjectSpec } from '@/schema/project-spec';
import versions from '../../versions.json';

// =============================================================================
// Templates - Root Configuration
// =============================================================================

const ROOT_PACKAGE_JSON_TEMPLATE = `{
  "name": "{{name}}",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "workspaces": [
    "packages/*",
    "apps/*"
  ],
  "scripts": {
    "dev": "bun run --filter '*' dev",
    "build": "bun run --filter '*' build",
    "test": "bun run --filter '*' test",
    "typecheck": "bun run --filter '*' typecheck",
    "lint": "bunx biome check .",
    "lint:fix": "bunx biome check --write .",
    "format": "bunx biome format --write .",
    "validate": "bun run typecheck && bun run lint && bun run test"
  },
  "devDependencies": {
    "@biomejs/biome": "^{{biomeVersion}}",
    "typescript": "^{{typescriptVersion}}"
  },
  "engines": {
    "bun": ">={{bunVersion}}"
  }
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
    "test": "bun test"
  },
  "dependencies": {
    "zod": "^{{zodVersion}}"
  },
  "devDependencies": {
    "@types/bun": "^{{bunTypesVersion}}",
    "typescript": "^{{typescriptVersion}}"
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

# Bun
bun.lockb
.bun/

# Environment
.env
.env.local
.env.*.local
.envrc.local

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
`;

const ENVRC_TEMPLATE = `# Enable Nix flake dev shell
if [ -f flake.nix ]; then
  use flake
fi

# Add local scripts to PATH
PATH_add ./scripts
PATH_add ./node_modules/.bin

# Minimal logging in multiplexers
if [[ -n "$ZELLIJ" || -n "$TMUX" ]]; then
  export DIRENV_LOG_FORMAT=""
fi

# Load local overrides
if [ -f .envrc.local ]; then
  source_env .envrc.local
fi
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
            bun
            nodejs_22

            # TypeScript tooling
            typescript
            nodePackages.typescript-language-server

            # Utilities
            jq
            fd
            ripgrep
          ];

          shellHook = ''
            echo "{{name}} Development Shell"
            echo "  bun install  - Install dependencies"
            echo "  bun dev      - Start all dev servers"
            echo "  bun validate - Run all checks"
          '';
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}`;

const README_TEMPLATE = `# {{name}}

Monorepo powered by Bun workspaces.

## Structure

\`\`\`
{{name}}/
├── apps/              # Deployable applications
│   └── ...
├── packages/          # Shared packages
│   └── shared/        # Common utilities and types
├── package.json       # Root workspace config
├── tsconfig.json      # TypeScript project references
├── tsconfig.base.json # Shared TypeScript settings
├── biome.json         # Linting and formatting
└── flake.nix          # Nix development shell
\`\`\`

## Getting Started

\`\`\`bash
# Install dependencies
bun install

# Start development
bun dev

# Run all checks
bun validate
\`\`\`

## Workspaces

- \`packages/shared\` - Common utilities (@{{name}}/shared)
- \`apps/*\` - Deployable applications

## Scripts

| Command | Description |
|---------|-------------|
| \`bun dev\` | Start all dev servers |
| \`bun build\` | Build all packages |
| \`bun test\` | Run all tests |
| \`bun validate\` | Typecheck + lint + test |
`;

// =============================================================================
// Generator
// =============================================================================

/**
 * Generate Bun workspaces monorepo structure
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
    // Versions from single source of truth
    zodVersion: npmVersions['zod'],
    typescriptVersion: npmVersions['typescript'],
    biomeVersion: npmVersions['@biomejs/biome'],
    bunTypesVersion: npmVersions['@types/bun'],
    bunVersion: runtimeVersions['bun'],
  };

  const templates: FileTree = {
    // Root configuration
    'package.json': ROOT_PACKAGE_JSON_TEMPLATE,
    'tsconfig.json': ROOT_TSCONFIG_TEMPLATE,
    'tsconfig.base.json': TSCONFIG_BASE_TEMPLATE,
    'biome.json': BIOME_JSON_TEMPLATE,

    // Shared package
    'packages/shared/package.json': SHARED_PACKAGE_JSON_TEMPLATE,
    'packages/shared/tsconfig.json': SHARED_TSCONFIG_TEMPLATE,
    'packages/shared/src/index.ts': SHARED_INDEX_TS_TEMPLATE,

    // Infrastructure
    '.gitignore': GITIGNORE_TEMPLATE,
    '.envrc': ENVRC_TEMPLATE,
    'flake.nix': FLAKE_NIX_TEMPLATE,
    'README.md': README_TEMPLATE,
  };

  return renderTemplates(templates, data);
};
