import { describe, test, expect } from 'bun:test';
import { $ } from 'bun';

/**
 * Tests for verification-gate Stop hook
 *
 * This hook queries the verification_claims table for pending claims
 * and blocks session completion if any exist.
 *
 * Exit code semantics (Claude Code):
 *   0 = allow (JSON parsed for continue: true/false)
 *   2 = block (stderr used as error message)
 *   1 = non-blocking error (stderr shown, continues)
 */
describe('verification-gate hook', () => {
  const hookPath = `${import.meta.dir}/verification-gate.ts`;

  test('allows when no pending claims (nonexistent session)', async () => {
    const input = JSON.stringify({
      hook_event_name: 'Stop',
      session_id: 'nonexistent-session-id',
    });

    const result = await $`echo ${input} | bun run ${hookPath}`.nothrow();

    expect(result.exitCode).toBe(0); // No claims = allow
  });

  test('allows for non-Stop events', async () => {
    const input = JSON.stringify({
      hook_event_name: 'PreToolUse',
      session_id: 'test-session',
    });

    const result = await $`echo ${input} | bun run ${hookPath}`.nothrow();

    expect(result.exitCode).toBe(0); // Wrong event type = allow
  });

  test('allows on invalid JSON input (fail-safe)', async () => {
    const result = await $`echo "not valid json" | bun run ${hookPath}`.nothrow();

    expect(result.exitCode).toBe(0); // Fail-safe: allow
  });

  test('allows when database does not exist (fail-safe)', async () => {
    // Temporarily set HOME to a location without the database
    const input = JSON.stringify({
      hook_event_name: 'Stop',
      session_id: 'test-session',
    });

    // The hook handles missing database gracefully
    const result = await $`HOME=/nonexistent echo ${input} | bun run ${hookPath}`.nothrow();

    expect(result.exitCode).toBe(0); // Fail-safe: allow when DB missing
  });

  test('allows with empty input', async () => {
    const result = await $`echo "" | bun run ${hookPath}`.nothrow();

    expect(result.exitCode).toBe(0); // Fail-safe: allow
  });

  // Note: Testing blocking behavior requires a real database with pending claims
  // This would need integration test setup with SQLite database
  // For now, we verify the fail-safe behavior works correctly
});
