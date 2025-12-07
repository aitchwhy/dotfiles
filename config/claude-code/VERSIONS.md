# Tech Stack Versions
## December 2025 — Frozen

> **Purpose**: Exact version pinning for reproducible environments.
> **Updated**: December 6, 2025

---

## Runtime

| Tool | Minimum | Recommended | Notes |
|------|---------|-------------|-------|
| **Bun** | 1.3.0 | 1.3.3+ | Primary runtime, test runner, package manager |
| **Node.js** | 22.0.0 | 22 LTS | Fallback only when Bun incompatible |
| **UV** | 0.5.0 | 0.5+ | Python package manager (NEVER pip) |

---

## TypeScript Ecosystem

| Package | Version | Notes |
|---------|---------|-------|
| **TypeScript** | 5.9.3+ | Strict mode mandatory |
| **Zod** | 4.1+ | Schema validation (NOT zod/v3) |
| **Biome** | 2.3.8+ | Lint + format (NOT ESLint/Prettier) |

---

## Frontend

| Package | Version | Notes |
|---------|---------|-------|
| **React** | 19.2+ | Server Components, Actions, `use()` hook |
| **TanStack Router** | 1.120+ | Type-safe file-based routing |
| **TanStack Query** | 5.65+ | Server state management |
| **Tailwind CSS** | 4.1+ | V4 CSS-first config |
| **shadcn/ui** | Latest | Copy-paste Radix components |

---

## Backend

| Package | Version | Notes |
|---------|---------|-------|
| **HonoJS** | 4.10+ | Web Standard API (NOT Express/Fastify) |
| **Drizzle ORM** | 0.44+ | Type-safe SQL (NOT Prisma) |
| **D1/Turso/Neon** | Latest | SQLite or Postgres |

---

## Python

| Package | Version | Notes |
|---------|---------|-------|
| **Python** | 3.13+ | Via UV only |
| **Pydantic** | 2.10+ | Schema validation |
| **Ruff** | 0.8+ | Lint + format (NOT Black/isort/flake8) |

---

## Infrastructure

| Tool | Version | Notes |
|------|---------|-------|
| **Nix** | 24.11+ | Flakes enabled |
| **nix-darwin** | Latest | macOS system config |
| **Home Manager** | Latest | User environment |
| **Cloudflare Workers** | Latest | Edge deployment |
| **Fly.io** | Latest | Container deployment |

---

## Forbidden Tools

| Tool | Reason | Replacement |
|------|--------|-------------|
| npm / yarn / pnpm | Use Bun | `bun install` |
| ESLint | Use Biome | `bunx biome check` |
| Prettier | Use Biome | `bunx biome format` |
| Jest | Use Bun | `bun test` |
| Express | Use Hono | `hono` |
| Fastify | Use Hono | `hono` |
| Prisma | Use Drizzle | `drizzle-orm` |
| pip | Use UV | `uv pip` |
| zod/v3 | Use v4 | `import { z } from 'zod'` |

---

## Lockfile Reference

| Package Manager | Lockfile | Status |
|-----------------|----------|--------|
| Bun | `bun.lockb` | ✅ Required |
| npm | `package-lock.json` | ❌ Forbidden |
| yarn | `yarn.lock` | ❌ Forbidden |
| pnpm | `pnpm-lock.yaml` | ❌ Forbidden |

---

## Config File Reference

| Purpose | File | Status |
|---------|------|--------|
| Linting | `biome.json` | ✅ Required |
| Linting | `.eslintrc*` | ❌ Forbidden |
| Formatting | `biome.json` | ✅ Required |
| Formatting | `.prettierrc*` | ❌ Forbidden |
| Testing | Native `bun test` | ✅ Required |
| Testing | `jest.config.*` | ❌ Forbidden |
| ORM | `drizzle.config.ts` | ✅ Preferred |
| ORM | `prisma/schema.prisma` | ❌ Forbidden |

---

*Last verified: December 6, 2025*
