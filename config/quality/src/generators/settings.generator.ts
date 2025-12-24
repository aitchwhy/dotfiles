/**
 * Settings Generator
 *
 * Generates complete Claude Code settings.json.
 * Imports HOOK_DEFINITIONS for all 4 hook types.
 */

import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import { Effect } from 'effect';
import { HOOK_DEFINITIONS } from '../hooks/definitions';
import type { PersonaDefinition } from '../schemas';

// =============================================================================
// Permissions SSOT
// =============================================================================

const PERMISSIONS = {
  allow: [
    'Read',
    'Grep(*)',
    'Glob(*)',
    'WebSearch',

    'Bash(ls:*)',
    'Bash(cat:*)',
    'Bash(head:*)',
    'Bash(tail:*)',
    'Bash(find:*)',
    'Bash(fd:*)',
    'Bash(rg:*)',
    'Bash(grep:*)',
    'Bash(wc:*)',
    'Bash(which:*)',
    'Bash(echo:*)',
    'Bash(pwd)',
    'Bash(mkdir:*)',
    'Bash(cp:*)',
    'Bash(mv:*)',
    'Bash(rm:*)',
    'Bash(touch:*)',
    'Bash(tree:*)',
    'Bash(eza:*)',
    'Bash(bat:*)',
    'Bash(delta:*)',
    'Bash(sort:*)',
    'Bash(uniq:*)',
    'Bash(jq:*)',
    'Bash(curl:*)',
    'Bash(open:*)',
    'Bash(readlink:*)',
    'Bash(xargs:*)',
    'Bash(sh:*)',

    'Bash(git:*)',
    'Bash(GIT_PAGER=cat git:*)',
    'Bash(gh:*)',
    'Bash(LEFTHOOK=0 git commit:*)',

    'Bash(pnpm:*)',
    'Bash(npm:*)',
    'Bash(npx:*)',
    'Bash(node:*)',
    'Bash(python:*)',
    'Bash(python3:*)',
    'Bash(uv:*)',
    'Bash(uvx:*)',
    'Bash(ruff:*)',
    'Bash(pytest:*)',
    'Bash(bun:*)',
    'Bash(just:*)',
    'Bash(make:*)',
    'Bash(cargo:*)',

    'Bash(biome:*)',
    'Bash(oxlint:*)',
    'Bash(vitest:*)',
    'Bash(tsc:*)',
    'Bash(playwright:*)',

    'Bash(docker:*)',
    'Bash(docker-compose:*)',
    'Bash(pulumi:*)',
    'Bash(esc:*)',
    'Bash(wrangler:*)',
    'Bash(kubectl:*)',
    'Bash(terraform:*)',

    'Bash(nix:*)',
    'Bash(nix-shell:*)',
    'Bash(darwin-rebuild:*)',
    'Bash(home-manager:*)',
    'Bash(sudo darwin-rebuild:*)',
    'Bash(alejandra:*)',
    'Bash(nixfmt:*)',
    'Bash(shfmt:*)',
    'Bash(stylua:*)',

    'Bash(pgrep:*)',
    'Bash(killall:*)',
    'Bash(launchctl:*)',
    'Bash(sudo launchctl:*)',
    'Bash(defaults read:*)',
    'Bash(osascript:*)',
    'Bash(sw_vers:*)',
    'Bash(mdfind:*)',
    'Bash(infocmp:*)',

    'Bash(sqlite3:*)',
    'Bash(tree-sitter:*)',
    'Bash(tldr:*)',
    'Bash(fc-list:*)',
    'Bash(nvim:*)',
    'Bash(ghostty:*)',
    'Bash(zellij:*)',
    'Bash(claude:*)',

    'Write(*)',
    'Edit(*)',

    'WebFetch(domain:github.com)',
    'WebFetch(domain:raw.githubusercontent.com)',
    'WebFetch(domain:gist.github.com)',
    'WebFetch(domain:gist.githubusercontent.com)',
    'WebFetch(domain:docs.anthropic.com)',
    'WebFetch(domain:effect.website)',
    'WebFetch(domain:ghostty.org)',
    'WebFetch(domain:zellij.dev)',
    'WebFetch(domain:www.lazyvim.org)',
    'WebFetch(domain:macos-defaults.com)',
    'WebFetch(domain:apps.apple.com)',

    'mcp__context7__resolve-library-id',
    'mcp__context7__get-library-docs',
  ],
  deny: [
    'Read(**/.env*)',
    'Read(**/secrets*)',
    'Read(**/*.pem)',
    'Read(**/*.key)',
    'Read(**/.ssh/*)',
    'Read(**/.gnupg/*)',
    'Read(**/.netrc)',
    'Write(**/.env*)',
    'Write(**/.git/*)',
    'Edit(**/.git/*)',
    'Bash(rm -rf /)',
    'Bash(rm -rf ~)',
    'Bash(sudo rm -rf:*)',
    'Bash(chmod 777:*)',
    'Bash(git push --force:*)',
    'Bash(git reset --hard:*)',
  ],
} as const;

// =============================================================================
// Enabled Plugins SSOT
// =============================================================================

const ENABLED_PLUGINS = {
  'code-review@claude-code-plugins': true,
  'commit-commands@claude-code-plugins': true,
  'explanatory-output-style@claude-code-plugins': true,
  'feature-dev@claude-code-plugins': true,
  'frontend-design@claude-code-plugins': true,
  'learning-output-style@claude-code-plugins': true,
  'pr-review-toolkit@claude-code-plugins': true,
  'ralph-wiggum@claude-code-plugins': true,
} as const;

// =============================================================================
// Settings Type
// =============================================================================

type ClaudeSettings = {
  readonly $schema: string;
  readonly $comment: string;
  readonly cleanupPeriodDays: number;
  readonly includeCoAuthoredBy: boolean;
  readonly alwaysThinkingEnabled: boolean;
  readonly verbose: boolean;
  readonly permissions: typeof PERMISSIONS;
  readonly hooks: typeof HOOK_DEFINITIONS;
  readonly agents: readonly {
    readonly name: string;
    readonly description: string;
    readonly model?: string;
  }[];
  readonly enabledPlugins: typeof ENABLED_PLUGINS;
};

// =============================================================================
// Generator
// =============================================================================

const generateSettings = (personas: readonly PersonaDefinition[]): ClaudeSettings => ({
  $schema: 'https://json.schemastore.org/claude-code-settings.json',
  $comment: 'Generated by Quality System. Do not edit manually.',
  cleanupPeriodDays: 99999,
  includeCoAuthoredBy: false,
  alwaysThinkingEnabled: true,
  verbose: false,
  permissions: PERMISSIONS,
  hooks: HOOK_DEFINITIONS,
  agents: personas.map((p) => {
    const agent: {
      readonly name: string;
      readonly description: string;
      readonly model?: string;
    } = { name: p.name, description: p.description };
    if (p.model !== undefined) {
      return { ...agent, model: p.model };
    }
    return agent;
  }),
  enabledPlugins: ENABLED_PLUGINS,
});

export const generateSettingsFile = (
  _skills: readonly unknown[],
  personas: readonly PersonaDefinition[],
  _hookPath: string,
  outDir: string
) =>
  Effect.gen(function* () {
    const settings = generateSettings(personas);
    const filePath = path.join(outDir, 'settings.json');

    yield* Effect.tryPromise(() => fs.writeFile(filePath, JSON.stringify(settings, null, 2)));

    yield* Effect.log(`Generated: ${filePath}`);
    return filePath;
  });
