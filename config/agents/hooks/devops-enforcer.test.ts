import { describe, expect, test } from 'bun:test';

/**
 * Tests for devops-enforcer PreToolUse hook
 *
 * This hook enforces Nix-first DevOps philosophy by blocking:
 * - Forbidden files: docker-compose.yml, Dockerfile, .dockerignore
 * - Forbidden commands: docker-compose, docker build, npm/bun run dev
 *
 * Exit code semantics:
 *   0 = success (JSON: { decision: 'approve' } or { decision: 'block', reason })
 *
 * Key behaviors:
 * - Blocks Docker-related files (use nix2container instead)
 * - Blocks docker-compose commands (use process-compose instead)
 * - Blocks npm/bun run dev (use process-compose instead)
 * - Allows process-compose, nix build, npm run build/test
 * - Fail-safe: allows on error
 */

type HookOutput = { decision: 'approve' } | { decision: 'block'; reason: string };

async function runHook(input: object): Promise<HookOutput> {
  const hookPath = `${import.meta.dir}/devops-enforcer.ts`;
  const proc = Bun.spawn(['bun', 'run', hookPath], {
    stdin: new Blob([JSON.stringify(input)]),
    stdout: 'pipe',
    stderr: 'pipe',
  });

  await proc.exited;
  const output = await new Response(proc.stdout).text();
  return JSON.parse(output.trim());
}

function makeInput(tool_name: string, tool_input: object) {
  return {
    hook_event_name: 'PreToolUse',
    session_id: 'test-session',
    tool_name,
    tool_input,
  };
}

describe('devops-enforcer hook', () => {
  describe('forbidden files', () => {
    test('blocks docker-compose.yml creation', async () => {
      const input = makeInput('Write', {
        file_path: 'docker-compose.yml',
        content: 'version: "3"',
      });

      const result = await runHook(input);
      expect(result.decision).toBe('block');
      expect((result as { reason: string }).reason).toContain('DEVOPS VIOLATION');
      expect((result as { reason: string }).reason).toContain('process-compose');
    });

    test('blocks docker-compose.yaml creation', async () => {
      const input = makeInput('Write', {
        file_path: '/path/to/docker-compose.yaml',
        content: 'version: "3"',
      });

      const result = await runHook(input);
      expect(result.decision).toBe('block');
    });

    test('blocks Dockerfile creation', async () => {
      const input = makeInput('Write', {
        file_path: 'Dockerfile',
        content: 'FROM node:20',
      });

      const result = await runHook(input);
      expect(result.decision).toBe('block');
      expect((result as { reason: string }).reason).toContain('nix2container');
    });

    test('blocks Dockerfile.dev creation', async () => {
      const input = makeInput('Write', {
        file_path: 'Dockerfile.dev',
        content: 'FROM node:20',
      });

      const result = await runHook(input);
      expect(result.decision).toBe('block');
    });

    test('blocks Dockerfile.prod creation', async () => {
      const input = makeInput('Write', {
        file_path: '/app/Dockerfile.prod',
        content: 'FROM node:20',
      });

      const result = await runHook(input);
      expect(result.decision).toBe('block');
    });

    test('blocks .dockerignore creation', async () => {
      const input = makeInput('Write', {
        file_path: '.dockerignore',
        content: 'node_modules',
      });

      const result = await runHook(input);
      expect(result.decision).toBe('block');
    });
  });

  describe('allowed files', () => {
    test('allows process-compose.yaml creation', async () => {
      const input = makeInput('Write', {
        file_path: 'process-compose.yaml',
        content: 'version: "0.5"',
      });

      const result = await runHook(input);
      expect(result.decision).toBe('approve');
    });

    test('allows process-compose.yml creation', async () => {
      const input = makeInput('Write', {
        file_path: 'process-compose.yml',
        content: 'version: "0.5"',
      });

      const result = await runHook(input);
      expect(result.decision).toBe('approve');
    });

    test('allows flake.nix creation', async () => {
      const input = makeInput('Write', {
        file_path: 'flake.nix',
        content: '{ outputs = { ... }: {}; }',
      });

      const result = await runHook(input);
      expect(result.decision).toBe('approve');
    });

    test('allows regular TypeScript files', async () => {
      const input = makeInput('Write', {
        file_path: 'src/index.ts',
        content: 'console.log("hello");',
      });

      const result = await runHook(input);
      expect(result.decision).toBe('approve');
    });

    test('allows package.json', async () => {
      const input = makeInput('Write', {
        file_path: 'package.json',
        content: '{ "name": "test" }',
      });

      const result = await runHook(input);
      expect(result.decision).toBe('approve');
    });
  });

  describe('forbidden commands', () => {
    test('blocks docker-compose up', async () => {
      const input = makeInput('Bash', { command: 'docker-compose up' });

      const result = await runHook(input);
      expect(result.decision).toBe('block');
      expect((result as { reason: string }).reason).toContain('DEVOPS VIOLATION');
      expect((result as { reason: string }).reason).toContain('process-compose');
    });

    test('blocks docker-compose up -d', async () => {
      const input = makeInput('Bash', { command: 'docker-compose up -d api' });

      const result = await runHook(input);
      expect(result.decision).toBe('block');
    });

    test('blocks docker compose up (new syntax)', async () => {
      const input = makeInput('Bash', { command: 'docker compose up' });

      const result = await runHook(input);
      expect(result.decision).toBe('block');
    });

    test('blocks docker-compose start', async () => {
      const input = makeInput('Bash', { command: 'docker-compose start' });

      const result = await runHook(input);
      expect(result.decision).toBe('block');
    });

    test('blocks docker-compose run', async () => {
      const input = makeInput('Bash', { command: 'docker-compose run api bash' });

      const result = await runHook(input);
      expect(result.decision).toBe('block');
    });

    test('blocks docker-compose exec', async () => {
      const input = makeInput('Bash', { command: 'docker-compose exec db psql' });

      const result = await runHook(input);
      expect(result.decision).toBe('block');
    });

    test('blocks docker-compose build', async () => {
      const input = makeInput('Bash', { command: 'docker-compose build' });

      const result = await runHook(input);
      expect(result.decision).toBe('block');
    });

    test('blocks docker build', async () => {
      const input = makeInput('Bash', { command: 'docker build -t myapp .' });

      const result = await runHook(input);
      expect(result.decision).toBe('block');
      expect((result as { reason: string }).reason).toContain('nix build');
    });

    test('blocks npm run dev', async () => {
      const input = makeInput('Bash', { command: 'npm run dev' });

      const result = await runHook(input);
      expect(result.decision).toBe('block');
      expect((result as { reason: string }).reason).toContain('process-compose');
    });

    test('blocks bun run dev', async () => {
      const input = makeInput('Bash', { command: 'bun run dev' });

      const result = await runHook(input);
      expect(result.decision).toBe('block');
    });

    test('blocks yarn run dev', async () => {
      const input = makeInput('Bash', { command: 'yarn run dev' });

      const result = await runHook(input);
      expect(result.decision).toBe('block');
    });

    test('blocks pnpm run dev', async () => {
      const input = makeInput('Bash', { command: 'pnpm run dev' });

      const result = await runHook(input);
      expect(result.decision).toBe('block');
    });

    test('blocks npm run start', async () => {
      const input = makeInput('Bash', { command: 'npm run start' });

      const result = await runHook(input);
      expect(result.decision).toBe('block');
    });

    test('blocks npm run serve', async () => {
      const input = makeInput('Bash', { command: 'npm run serve' });

      const result = await runHook(input);
      expect(result.decision).toBe('block');
    });

    test('blocks npm start', async () => {
      const input = makeInput('Bash', { command: 'npm start' });

      const result = await runHook(input);
      expect(result.decision).toBe('block');
    });
  });

  describe('allowed commands', () => {
    test('allows process-compose up', async () => {
      const input = makeInput('Bash', { command: 'process-compose up' });

      const result = await runHook(input);
      expect(result.decision).toBe('approve');
    });

    test('allows process-compose up api', async () => {
      const input = makeInput('Bash', { command: 'process-compose up api' });

      const result = await runHook(input);
      expect(result.decision).toBe('approve');
    });

    test('allows process-compose down', async () => {
      const input = makeInput('Bash', { command: 'process-compose down' });

      const result = await runHook(input);
      expect(result.decision).toBe('approve');
    });

    test('allows nix build', async () => {
      const input = makeInput('Bash', { command: 'nix build .#api' });

      const result = await runHook(input);
      expect(result.decision).toBe('approve');
    });

    test('allows nix run', async () => {
      const input = makeInput('Bash', { command: 'nix run .#api' });

      const result = await runHook(input);
      expect(result.decision).toBe('approve');
    });

    test('allows nix develop', async () => {
      const input = makeInput('Bash', { command: 'nix develop' });

      const result = await runHook(input);
      expect(result.decision).toBe('approve');
    });

    test('allows npm run build', async () => {
      const input = makeInput('Bash', { command: 'npm run build' });

      const result = await runHook(input);
      expect(result.decision).toBe('approve');
    });

    test('allows bun run build', async () => {
      const input = makeInput('Bash', { command: 'bun run build' });

      const result = await runHook(input);
      expect(result.decision).toBe('approve');
    });

    test('allows npm run test', async () => {
      const input = makeInput('Bash', { command: 'npm run test' });

      const result = await runHook(input);
      expect(result.decision).toBe('approve');
    });

    test('allows bun test', async () => {
      const input = makeInput('Bash', { command: 'bun test' });

      const result = await runHook(input);
      expect(result.decision).toBe('approve');
    });

    test('allows npm run lint', async () => {
      const input = makeInput('Bash', { command: 'npm run lint' });

      const result = await runHook(input);
      expect(result.decision).toBe('approve');
    });

    test('allows npm run typecheck', async () => {
      const input = makeInput('Bash', { command: 'npm run typecheck' });

      const result = await runHook(input);
      expect(result.decision).toBe('approve');
    });

    test('allows git commands', async () => {
      const input = makeInput('Bash', { command: 'git status' });

      const result = await runHook(input);
      expect(result.decision).toBe('approve');
    });
  });

  describe('fail-safe behavior', () => {
    test('allows on empty input', async () => {
      const hookPath = `${import.meta.dir}/devops-enforcer.ts`;
      const proc = Bun.spawn(['bun', 'run', hookPath], {
        stdin: new Blob(['']),
        stdout: 'pipe',
        stderr: 'pipe',
      });

      await proc.exited;
      const output = await new Response(proc.stdout).text();
      const result = JSON.parse(output.trim());
      expect(result.decision).toBe('approve');
    });

    test('allows on malformed JSON', async () => {
      const hookPath = `${import.meta.dir}/devops-enforcer.ts`;
      const proc = Bun.spawn(['bun', 'run', hookPath], {
        stdin: new Blob(['not valid json {']),
        stdout: 'pipe',
        stderr: 'pipe',
      });

      await proc.exited;
      const output = await new Response(proc.stdout).text();
      const result = JSON.parse(output.trim());
      expect(result.decision).toBe('approve');
    });

    test('allows on missing required fields', async () => {
      const hookPath = `${import.meta.dir}/devops-enforcer.ts`;
      const proc = Bun.spawn(['bun', 'run', hookPath], {
        stdin: new Blob([JSON.stringify({ tool_name: 'Write' })]),
        stdout: 'pipe',
        stderr: 'pipe',
      });

      await proc.exited;
      const output = await new Response(proc.stdout).text();
      const result = JSON.parse(output.trim());
      expect(result.decision).toBe('approve');
    });

    test('allows unknown tool names', async () => {
      const input = makeInput('UnknownTool', { whatever: 'data' });

      const result = await runHook(input);
      expect(result.decision).toBe('approve');
    });
  });

  describe('Edit tool', () => {
    test('blocks editing docker-compose.yml', async () => {
      const input = makeInput('Edit', {
        file_path: 'docker-compose.yml',
        new_string: 'services:',
      });

      const result = await runHook(input);
      expect(result.decision).toBe('block');
    });

    test('allows editing process-compose.yaml', async () => {
      const input = makeInput('Edit', {
        file_path: 'process-compose.yaml',
        new_string: 'processes:',
      });

      const result = await runHook(input);
      expect(result.decision).toBe('approve');
    });
  });
});
