/**
 * Twelve Factor Skill Definition
 *
 * 12-Factor App methodology for Nix dotfiles and TypeScript.
 * Migrated from: config/claude-code/skills/twelve-factor/SKILL.md
 */
import type { SystemSkill } from '@/schema'

export const twelveFactorSkill: SystemSkill = {
  name: 'twelve-factor' as SystemSkill['name'],
  description:
    '12-Factor App methodology applied to Nix dotfiles and modern TypeScript. Reproducible builds, environment config, dev/prod parity.',
  allowedTools: ['Read', 'Write', 'Edit', 'Grep', 'Glob', 'Bash'] as SystemSkill['allowedTools'],

  sections: [
    {
      title: 'I. Codebase',
      content: `**Principle**: One codebase tracked in version control, many deploys.

Each machine is a "deploy" of the same dotfiles codebase.`,
    },
    {
      title: 'II. Dependencies',
      patterns: [
        {
          title: 'Explicitly Declare All Dependencies',
          annotation: 'do',
          language: 'nix',
          code: `# Bad: assumes system has curl
environment.systemPackages = [ pkgs.jq ];

# Good: explicitly declare all
environment.systemPackages = with pkgs; [ curl jq ];

# Dev shells with all tools
devShells.default = pkgs.mkShell {
  packages = with pkgs; [ bun biome typescript ];
};`,
        },
      ],
    },
    {
      title: 'III. Config',
      patterns: [
        {
          title: 'Environment-Driven Configuration',
          annotation: 'do',
          language: 'typescript',
          code: `// Bad: hardcoded
const API_URL = 'https://api.production.com';

// Good: environment-driven
const config = {
  apiUrl: process.env.API_URL ?? 'http://localhost:3000',
  dbHost: process.env.DB_HOST ?? 'localhost',
} as const;`,
        },
      ],
    },
    {
      title: 'V. Build, Release, Run',
      patterns: [
        {
          title: 'Strict Separation',
          annotation: 'info',
          language: 'bash',
          code: `# Build: Convert code to executable
nix build .#darwinConfigurations.hostname.system

# Release: Combine build with config
darwin-rebuild switch --flake .#hostname

# TypeScript
bun run build  # Build
bun run start  # Run`,
        },
      ],
    },
    {
      title: 'IX. Disposability',
      patterns: [
        {
          title: 'Graceful Shutdown',
          annotation: 'do',
          language: 'typescript',
          code: `// Lazy initialization
const db = createLazyConnection(() => connectToDatabase());

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('Shutting down gracefully...');
  await server.close();
  await db.disconnect();
  process.exit(0);
});`,
        },
      ],
    },
    {
      title: 'X. Dev/Prod Parity',
      patterns: [
        {
          title: 'Nix Ensures Parity',
          annotation: 'do',
          language: 'nix',
          code: `# The same flake builds for all environments
darwin-rebuild switch --flake .#hostname  # Dev machine
nix build .#darwinConfigurations.hostname.system  # CI

# Same packages, same versions, same configuration`,
        },
      ],
    },
    {
      title: 'XI. Logs',
      patterns: [
        {
          title: 'Logs as Event Streams',
          annotation: 'do',
          language: 'typescript',
          code: `// Bad: writing to log files
fs.appendFileSync('/var/log/app.log', message);

// Good: structured stdout
console.log(JSON.stringify({
  timestamp: new Date().toISOString(),
  level: 'info',
  message: 'User logged in',
  userId: user.id,
}));`,
        },
      ],
    },
  ],
}
