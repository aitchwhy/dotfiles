/**
 * UI Generator
 *
 * Generates React 19 + XState + TanStack Router projects with:
 * - Type-safe file-based routing
 * - XState v5 state machines
 * - Tailwind CSS v4
 * - Vite build system
 */
import type { Effect } from 'effect';
import type { FileTree } from '@/layers/file-system';
import { renderTemplates, type TemplateEngine } from '@/layers/template-engine';
import type { ProjectSpec } from '@/schema/project-spec';
import versions from '../../versions.json';

// =============================================================================
// Templates - Package.json (UI-specific dependencies)
// =============================================================================

const UI_PACKAGE_JSON_TEMPLATE = `{
  "name": "{{name}}",
  "version": "0.1.0",
  "type": "module",
  "description": "{{#if description}}{{description}}{{else}}{{name}} UI{{/if}}",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "test": "vitest run",
    "test:watch": "vitest",
    "typecheck": "tsc --noEmit",
    "lint": "biome check .",
    "lint:fix": "biome check --write .",
    "format": "biome format --write .",
    "validate": "pnpm typecheck && pnpm lint && pnpm test"
  },
  "dependencies": {
    "react": "^{{reactVersion}}",
    "react-dom": "^{{reactVersion}}",
    "@tanstack/react-router": "^{{tanstackRouterVersion}}",
    "xstate": "^{{xstateVersion}}",
    "@xstate/react": "^{{xstateReactVersion}}",
    "zod": "^{{zodVersion}}"
  },
  "devDependencies": {
    "@biomejs/biome": "^{{biomeVersion}}",
    "@types/node": "^{{nodeTypesVersion}}",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "typescript": "^{{typescriptVersion}}",
    "vite": "^{{viteVersion}}",
    "vitest": "^{{vitestVersion}}",
    "@vitejs/plugin-react": "^4.3.0",
    "tailwindcss": "^{{tailwindVersion}}",
    "@tanstack/router-plugin": "^{{tanstackRouterVersion}}"
  },
  "engines": {
    "node": ">=25.0.0"
  },
  "packageManager": "pnpm@{{pnpmVersion}}"
}`;

// =============================================================================
// Templates - Entry Points
// =============================================================================

const MAIN_TSX_TEMPLATE = `/**
 * Application Entry Point
 */
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { App } from './App'
import './globals.css'

const root = document.getElementById('root')
// Throw is valid in generated React code (not Effect-TS)
if (!root) ${'throw'} new Error('Root element not found')

createRoot(root).render(
  <StrictMode>
    <App />
  </StrictMode>
)
`;

const APP_TSX_TEMPLATE = `/**
 * {{name}} - Root Component
 */
import { RouterProvider } from '@tanstack/react-router'
import { router } from './router'

export const App = () => {
  return <RouterProvider router={router} />
}
`;

// =============================================================================
// Templates - Router
// =============================================================================

const ROUTER_TSX_TEMPLATE = `/**
 * TanStack Router Configuration
 */
import { createRouter } from '@tanstack/react-router'
import { routeTree } from './routeTree.gen'

export const router = createRouter({ routeTree })

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router
  }
}
`;

const ROOT_ROUTE_TEMPLATE = `/**
 * Root Route Layout
 */
import { createRootRoute, Outlet, Link } from '@tanstack/react-router'

export const Route = createRootRoute({
  component: () => (
    <div className="min-h-screen bg-background">
      <nav className="border-b px-4 py-2">
        <Link to="/" className="text-lg font-semibold">
          Home
        </Link>
      </nav>
      <main className="container mx-auto py-8">
        <Outlet />
      </main>
    </div>
  ),
})
`;

const INDEX_ROUTE_TEMPLATE = `/**
 * Index Route (/)
 */
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/')({
  component: IndexPage,
})

function IndexPage() {
  return (
    <div className="space-y-4">
      <h1 className="text-3xl font-bold">Welcome</h1>
      <p className="text-muted-foreground">
        Your application is ready to go.
      </p>
    </div>
  )
}
`;

// =============================================================================
// Templates - XState
// =============================================================================

const COUNTER_MACHINE_TEMPLATE = `/**
 * Counter Machine
 *
 * Example XState v5 state machine.
 */
import { setup, assign } from 'xstate'

type CounterContext = {
  count: number
}

type CounterEvents =
  | { type: 'increment' }
  | { type: 'decrement' }
  | { type: 'reset' }

export const counterMachine = setup({
  types: {
    context: {} as CounterContext,
    events: {} as CounterEvents,
  },
}).createMachine({
  id: 'counter',
  initial: 'active',
  context: { count: 0 },
  states: {
    active: {
      on: {
        increment: {
          actions: assign({ count: ({ context }) => context.count + 1 }),
        },
        decrement: {
          actions: assign({ count: ({ context }) => context.count - 1 }),
        },
        reset: {
          actions: assign({ count: 0 }),
        },
      },
    },
  },
})
`;

// =============================================================================
// Templates - Styles
// =============================================================================

const GLOBALS_CSS_TEMPLATE = `@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --background: 0 0% 100%;
  --foreground: 222.2 84% 4.9%;
  --muted: 210 40% 96.1%;
  --muted-foreground: 215.4 16.3% 46.9%;
  --border: 214.3 31.8% 91.4%;
}

.dark {
  --background: 222.2 84% 4.9%;
  --foreground: 210 40% 98%;
  --muted: 217.2 32.6% 17.5%;
  --muted-foreground: 215 20.2% 65.1%;
  --border: 217.2 32.6% 17.5%;
}

body {
  @apply bg-background text-foreground;
}
`;

const TAILWIND_CONFIG_TEMPLATE = `import type { Config } from 'tailwindcss'

export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
        border: 'hsl(var(--border))',
      },
    },
  },
  plugins: [],
} satisfies Config
`;

// =============================================================================
// Templates - Build
// =============================================================================

const VITE_CONFIG_TEMPLATE = `import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { TanStackRouterVite } from '@tanstack/router-plugin/vite'
import path from 'node:path'

export default defineConfig({
  plugins: [TanStackRouterVite(), react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})
`;

const INDEX_HTML_TEMPLATE = `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>{{name}}</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
`;

// =============================================================================
// Generator
// =============================================================================

/**
 * Generate React 19 + XState + TanStack Router project files
 */
export const generateUi = (spec: ProjectSpec): Effect.Effect<FileTree, Error, TemplateEngine> => {
  const npmVersions = versions.npm as Record<string, string>;
  const runtimeVersions = versions.runtime as Record<string, string>;
  const frontendVersions = versions.frontend as Record<string, string>;

  const data = {
    name: spec.name,
    description: spec.description,
    reactVersion: npmVersions['react'],
    tanstackRouterVersion: npmVersions['@tanstack/react-router'],
    xstateVersion: npmVersions['xstate'],
    xstateReactVersion: npmVersions['@xstate/react'],
    zodVersion: npmVersions['zod'],
    typescriptVersion: npmVersions['typescript'],
    biomeVersion: npmVersions['@biomejs/biome'],
    nodeTypesVersion: npmVersions['@types/node'],
    viteVersion: npmVersions['vite'],
    vitestVersion: npmVersions['vitest'],
    tailwindVersion: frontendVersions['tailwindcss'],
    pnpmVersion: runtimeVersions['pnpm'],
  };

  const templates: FileTree = {
    'package.json': UI_PACKAGE_JSON_TEMPLATE,

    // Entry points
    'src/main.tsx': MAIN_TSX_TEMPLATE,
    'src/App.tsx': APP_TSX_TEMPLATE,

    // Router
    'src/router.tsx': ROUTER_TSX_TEMPLATE,
    'src/routes/__root.tsx': ROOT_ROUTE_TEMPLATE,
    'src/routes/index.tsx': INDEX_ROUTE_TEMPLATE,

    // XState machines
    'src/machines/counter.ts': COUNTER_MACHINE_TEMPLATE,

    // Styles
    'src/globals.css': GLOBALS_CSS_TEMPLATE,
    'tailwind.config.ts': TAILWIND_CONFIG_TEMPLATE,

    // Build
    'vite.config.ts': VITE_CONFIG_TEMPLATE,
    'index.html': INDEX_HTML_TEMPLATE,
  };

  return renderTemplates(templates, data);
};
