/**
 * Core Generator
 *
 * The base generator that all other generators extend.
 * Generates the foundation for any TypeScript/Node.js project:
 * - package.json (pnpm)
 * - tsconfig.json
 * - biome.json
 * - flake.nix (pnpm + Docker)
 * - .gitignore
 * - .envrc (ESC fail-fast)
 * - src/index.ts
 * - src/lib/result.ts
 */
import type { Effect } from 'effect';
import type { FileTree } from '@/layers/file-system';
import { renderTemplates, type TemplateEngine } from '@/layers/template-engine';
import type { ProjectSpec } from '@/schema/project-spec';
import versions from '../../versions.json';

// =============================================================================
// Types
// =============================================================================

export interface CoreGeneratorConfig {
  readonly spec: ProjectSpec;
}

// =============================================================================
// Templates
// =============================================================================

const PACKAGE_JSON_TEMPLATE = `{
  "name": "{{name}}",
  "version": "0.1.0",
  "type": "module",
  "description": "{{#if description}}{{description}}{{else}}{{name}} project{{/if}}",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "start": "node dist/index.js",
    "build": "tsc",
    "test": "vitest run",
    "test:watch": "vitest",
    "typecheck": "tsc --noEmit",
    "lint": "biome check .",
    "lint:fix": "biome check --write .",
    "format": "biome format --write .",
    "validate": "pnpm typecheck && pnpm lint && pnpm test"
  },
  "dependencies": {
    "zod": "^{{zodVersion}}"
  },
  "devDependencies": {
    "@biomejs/biome": "^{{biomeVersion}}",
    "@types/node": "^{{nodeTypesVersion}}",
    "tsx": "^{{tsxVersion}}",
    "typescript": "^{{typescriptVersion}}",
    "vitest": "^{{vitestVersion}}"
  },
  "engines": {
    "node": ">=25.0.0"
  },
  "packageManager": "pnpm@{{pnpmVersion}}"
}`;

const TSCONFIG_JSON_TEMPLATE = `{
  "compilerOptions": {
    "target": "ES2024",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["ES2024"],
    "strict": true,
    "noEmit": true,
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
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*.ts", "tests/**/*.ts"],
  "exclude": ["node_modules"]
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
    "ignore": ["node_modules"]
  }
}`;

const FLAKE_NIX_TEMPLATE = `{
  description = "{{name}} - TypeScript/Node.js project";

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
            pnpm
            nodejs_22
            typescript
            nodePackages.typescript-language-server
            docker
            docker-compose
            jq
            fd
            ripgrep
          ];

          shellHook = ''
            echo "{{name}} Development Shell"
            echo "  pnpm dev      - Start development server"
            echo "  pnpm test     - Run tests (vitest)"
            echo "  pnpm validate - Run all checks"
          '';
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}`;

const GITIGNORE_TEMPLATE = `# Dependencies
node_modules/

# Build outputs
dist/
build/
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
`;

const ENVRC_TEMPLATE = `# Layer 1: Nix Development Shell
use flake

# Layer 2: Pulumi ESC Environment (REQUIRED - fail-fast)
if ! use_esc "{{escOrg}}/{{name}}/dev"; then
  log_error "FATAL: Pulumi ESC environment not available"
  exit 1
fi

# Layer 3: Fail-fast validation
: "\${DATABASE_URL:?FATAL: DATABASE_URL not set - check ESC}"

# Add local scripts and bins to PATH
PATH_add ./scripts
PATH_add ./node_modules/.bin

# Minimal logging in terminal multiplexers
if [[ -n "$ZELLIJ" || -n "$TMUX" ]]; then
  export DIRENV_LOG_FORMAT=""
fi
`;

const INDEX_TS_TEMPLATE = `/**
 * {{name}}
 *
 * {{#if description}}{{description}}{{else}}Main entry point{{/if}}
 */
import { Effect } from 'effect'

export const main = Effect.gen(function* () {
  yield* Effect.log('Hello from {{name}}!')
})

Effect.runPromise(main)
`;

const RESULT_TS_TEMPLATE = `/**
 * Result Type Utilities
 *
 * Standard Result type for fallible operations.
 * Never throw for expected failures - use Result instead.
 */

export type Result<T, E = Error> =
  | { readonly ok: true; readonly data: T }
  | { readonly ok: false; readonly error: E }

export const Ok = <T>(data: T): Result<T, never> => ({ ok: true, data })

export const Err = <E>(error: E): Result<never, E> => ({ ok: false, error })

export const isOk = <T, E>(result: Result<T, E>): result is { ok: true; data: T } => result.ok

export const isErr = <T, E>(result: Result<T, E>): result is { ok: false; error: E } => !result.ok

export const map = <T, U, E>(result: Result<T, E>, fn: (data: T) => U): Result<U, E> =>
  result.ok ? Ok(fn(result.data)) : result

export const flatMap = <T, U, E>(
  result: Result<T, E>,
  fn: (data: T) => Result<U, E>
): Result<U, E> => (result.ok ? fn(result.data) : result)

export const unwrapOr = <T, E>(result: Result<T, E>, defaultValue: T): T =>
  result.ok ? result.data : defaultValue

export const tryCatch = <T>(fn: () => T): Result<T, Error> => {
  try {
    return Ok(fn())
  } catch (e) {
    return Err(e instanceof Error ? e : new Error(String(e)))
  }
}

export const tryCatchAsync = async <T>(fn: () => Promise<T>): Promise<Result<T, Error>> => {
  try {
    return Ok(await fn())
  } catch (e) {
    return Err(e instanceof Error ? e : new Error(String(e)))
  }
}
`;

// =============================================================================
// Generator
// =============================================================================

const buildTemplateData = (spec: ProjectSpec) => {
  const npmVersions = versions.npm as Record<string, string>;
  const runtimeVersions = versions.runtime as Record<string, string>;
  return {
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
};

const CORE_TEMPLATES: FileTree = {
  'package.json': PACKAGE_JSON_TEMPLATE,
  'tsconfig.json': TSCONFIG_JSON_TEMPLATE,
  'biome.json': BIOME_JSON_TEMPLATE,
  'flake.nix': FLAKE_NIX_TEMPLATE,
  '.gitignore': GITIGNORE_TEMPLATE,
  '.envrc': ENVRC_TEMPLATE,
  'src/index.ts': INDEX_TS_TEMPLATE,
  'src/lib/result.ts': RESULT_TS_TEMPLATE,
};

/**
 * Generate core project files from ProjectSpec
 */
export const generateCore = (spec: ProjectSpec): Effect.Effect<FileTree, Error, TemplateEngine> =>
  renderTemplates(CORE_TEMPLATES, buildTemplateData(spec));
