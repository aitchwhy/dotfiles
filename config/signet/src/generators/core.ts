/**
 * Core Generator
 *
 * The base generator that all other generators extend.
 * Generates the foundation for any TypeScript/Bun project:
 * - package.json
 * - tsconfig.json
 * - biome.json
 * - flake.nix
 * - .gitignore
 * - .envrc
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
    "dev": "bun run --watch src/index.ts",
    "start": "bun run src/index.ts",
    "test": "bun test",
    "typecheck": "tsc --noEmit",
    "lint": "bunx biome check .",
    "lint:fix": "bunx biome check --write .",
    "format": "bunx biome format --write .",
    "validate": "bun run typecheck && bun run lint && bun test"
  },
  "dependencies": {
    "zod": "^{{zodVersion}}"
  },
  "devDependencies": {
    "@biomejs/biome": "^{{biomeVersion}}",
{{#if isBun}}
    "@types/bun": "^{{bunTypesVersion}}",
{{/if}}
    "typescript": "^{{typescriptVersion}}"
  },
  "engines": {
{{#if isBun}}
    "bun": ">={{bunVersion}}"
{{else}}
    "node": ">={{nodeVersion}}"
{{/if}}
  }
}`;

const TSCONFIG_JSON_TEMPLATE = `{
  "compilerOptions": {
    "target": "ES2024",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["ES2024"],
{{#if isBun}}
    "types": ["bun-types"],
{{/if}}
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
  description = "{{name}} - TypeScript/Bun project";

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
            echo "  bun dev      - Start development server"
            echo "  bun test     - Run tests"
            echo "  bun validate - Run all checks"
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

# Add local scripts and bins to PATH
PATH_add ./scripts
PATH_add ./node_modules/.bin

# Minimal logging in terminal multiplexers
if [[ -n "$ZELLIJ" || -n "$TMUX" ]]; then
  export DIRENV_LOG_FORMAT=""
fi

# Load local overrides (keep last)
if [ -f .envrc.local ]; then
  source_env .envrc.local
fi
`;

const INDEX_TS_TEMPLATE = `/**
 * {{name}}
 *
 * {{#if description}}{{description}}{{else}}Main entry point{{/if}}
 */

export const main = (): void => {
  console.log('Hello from {{name}}!')
}

main()
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

/**
 * Generate core project files from ProjectSpec
 *
 * Uses versions from versions.json as single source of truth.
 */
export const generateCore = (spec: ProjectSpec): Effect.Effect<FileTree, Error, TemplateEngine> => {
  const npmVersions = versions.npm as Record<string, string>;
  const runtimeVersions = versions.runtime as Record<string, string>;

  const data = {
    name: spec.name,
    description: spec.description,
    isBun: spec.infra.runtime === 'bun',
    isNode: spec.infra.runtime === 'node',
    // Versions from single source of truth
    zodVersion: npmVersions['zod'],
    typescriptVersion: npmVersions['typescript'],
    biomeVersion: npmVersions['@biomejs/biome'],
    bunTypesVersion: npmVersions['@types/bun'],
    bunVersion: runtimeVersions['bun'],
    nodeVersion: runtimeVersions['node'],
  };

  const templates: FileTree = {
    'package.json': PACKAGE_JSON_TEMPLATE,
    'tsconfig.json': TSCONFIG_JSON_TEMPLATE,
    'biome.json': BIOME_JSON_TEMPLATE,
    'flake.nix': FLAKE_NIX_TEMPLATE,
    '.gitignore': GITIGNORE_TEMPLATE,
    '.envrc': ENVRC_TEMPLATE,
    'src/index.ts': INDEX_TS_TEMPLATE,
    'src/lib/result.ts': RESULT_TS_TEMPLATE,
  };

  return renderTemplates(templates, data);
};
