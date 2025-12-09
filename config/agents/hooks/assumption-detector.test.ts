import { describe, test, expect, beforeAll, afterAll } from 'bun:test';
import { $ } from 'bun';

/**
 * Tests for assumption-detector Stop hook
 *
 * This hook scans session transcripts for banned "should" language
 * and blocks session completion when high-severity patterns are found.
 *
 * Exit code semantics (Claude Code):
 *   0 = allow (JSON parsed for continue: true/false)
 *   2 = block (stderr used as error message)
 *   1 = non-blocking error (stderr shown, continues)
 */
describe('assumption-detector hook', () => {
  const hookPath = `${import.meta.dir}/assumption-detector.ts`;

  // Test transcripts
  const transcriptDir = '/tmp/assumption-detector-tests';

  beforeAll(async () => {
    await $`mkdir -p ${transcriptDir}`.nothrow();
  });

  afterAll(async () => {
    await $`rm -rf ${transcriptDir}`.nothrow();
  });

  test('blocks on "should work" language (high severity)', async () => {
    const tmpFile = `${transcriptDir}/should-work.txt`;
    await Bun.write(tmpFile, 'The code should work now after these changes.');

    const input = JSON.stringify({
      hook_event_name: 'Stop',
      session_id: 'test-session-1',
      transcript_path: tmpFile,
    });

    const result = await $`echo ${input} | bun run ${hookPath}`.nothrow();

    expect(result.exitCode).toBe(2); // Exit code 2 = blocking error
    expect(result.stderr.toString()).toContain('BLOCKED');
    expect(result.stderr.toString()).toContain('should work');
  });

  test('blocks on "this fixes" language (high severity)', async () => {
    const tmpFile = `${transcriptDir}/this-fixes.txt`;
    await Bun.write(tmpFile, 'This fixes the bug we discussed earlier.');

    const input = JSON.stringify({
      hook_event_name: 'Stop',
      session_id: 'test-session-2',
      transcript_path: tmpFile,
    });

    const result = await $`echo ${input} | bun run ${hookPath}`.nothrow();

    expect(result.exitCode).toBe(2);
    expect(result.stderr.toString()).toContain('BLOCKED');
  });

  test('blocks on "will now have" language (high severity)', async () => {
    const tmpFile = `${transcriptDir}/will-now-have.txt`;
    await Bun.write(tmpFile, 'The system will now have better performance.');

    const input = JSON.stringify({
      hook_event_name: 'Stop',
      session_id: 'test-session-3',
      transcript_path: tmpFile,
    });

    const result = await $`echo ${input} | bun run ${hookPath}`.nothrow();

    expect(result.exitCode).toBe(2);
    expect(result.stderr.toString()).toContain('BLOCKED');
  });

  test('allows clean transcripts with verified language', async () => {
    const tmpFile = `${transcriptDir}/verified.txt`;
    await Bun.write(tmpFile, 'VERIFIED via unit test: assertion passed.');

    const input = JSON.stringify({
      hook_event_name: 'Stop',
      session_id: 'test-session-4',
      transcript_path: tmpFile,
    });

    const result = await $`echo ${input} | bun run ${hookPath}`.nothrow();

    expect(result.exitCode).toBe(0); // Exit code 0 = allow
  });

  test('allows empty transcripts', async () => {
    const tmpFile = `${transcriptDir}/empty.txt`;
    await Bun.write(tmpFile, '');

    const input = JSON.stringify({
      hook_event_name: 'Stop',
      session_id: 'test-session-5',
      transcript_path: tmpFile,
    });

    const result = await $`echo ${input} | bun run ${hookPath}`.nothrow();

    expect(result.exitCode).toBe(0);
  });

  test('allows when transcript_path is missing', async () => {
    const input = JSON.stringify({
      hook_event_name: 'Stop',
      session_id: 'test-session-6',
      // No transcript_path
    });

    const result = await $`echo ${input} | bun run ${hookPath}`.nothrow();

    expect(result.exitCode).toBe(0); // Fail-safe: allow
  });

  test('allows when transcript file does not exist', async () => {
    const input = JSON.stringify({
      hook_event_name: 'Stop',
      session_id: 'test-session-7',
      transcript_path: '/nonexistent/path/to/transcript.txt',
    });

    const result = await $`echo ${input} | bun run ${hookPath}`.nothrow();

    expect(result.exitCode).toBe(0); // Fail-safe: allow
  });

  test('allows on invalid JSON input (fail-safe)', async () => {
    const result = await $`echo "not valid json" | bun run ${hookPath}`.nothrow();

    expect(result.exitCode).toBe(0); // Fail-safe: allow
  });

  test('warns but allows medium severity patterns', async () => {
    const tmpFile = `${transcriptDir}/probably-works.txt`;
    await Bun.write(tmpFile, 'The implementation probably works correctly.');

    const input = JSON.stringify({
      hook_event_name: 'Stop',
      session_id: 'test-session-8',
      transcript_path: tmpFile,
    });

    const result = await $`echo ${input} | bun run ${hookPath}`.nothrow();

    expect(result.exitCode).toBe(0); // Medium severity = warn, not block
    // Should have warning in JSON output
    const stdout = result.stdout.toString();
    expect(stdout).toContain('continue');
  });

  test('ignores patterns inside code blocks', async () => {
    const tmpFile = `${transcriptDir}/code-block.txt`;
    await Bun.write(
      tmpFile,
      `Here's a code example:
\`\`\`typescript
// This should work correctly
expect(result).toBe(true);
\`\`\`
The rest of the file is clean.`
    );

    const input = JSON.stringify({
      hook_event_name: 'Stop',
      session_id: 'test-session-9',
      transcript_path: tmpFile,
    });

    const result = await $`echo ${input} | bun run ${hookPath}`.nothrow();

    expect(result.exitCode).toBe(0); // Pattern in code block = ignore
  });

  test('ignores patterns inside quoted strings', async () => {
    const tmpFile = `${transcriptDir}/quoted.txt`;
    await Bun.write(tmpFile, 'The banned phrase "should work" is just an example here.');

    const input = JSON.stringify({
      hook_event_name: 'Stop',
      session_id: 'test-session-10',
      transcript_path: tmpFile,
    });

    const result = await $`echo ${input} | bun run ${hookPath}`.nothrow();

    expect(result.exitCode).toBe(0); // Pattern in quotes = ignore
  });

  test('ignores patterns inside inline code', async () => {
    const tmpFile = `${transcriptDir}/inline-code.txt`;
    await Bun.write(tmpFile, 'Use the pattern `should work` for testing assertions.');

    const input = JSON.stringify({
      hook_event_name: 'Stop',
      session_id: 'test-session-11',
      transcript_path: tmpFile,
    });

    const result = await $`echo ${input} | bun run ${hookPath}`.nothrow();

    expect(result.exitCode).toBe(0); // Pattern in inline code = ignore
  });

  test('still blocks patterns in plain prose', async () => {
    const tmpFile = `${transcriptDir}/plain-prose.txt`;
    await Bun.write(tmpFile, 'I made the changes and the code should work now.');

    const input = JSON.stringify({
      hook_event_name: 'Stop',
      session_id: 'test-session-12',
      transcript_path: tmpFile,
    });

    const result = await $`echo ${input} | bun run ${hookPath}`.nothrow();

    expect(result.exitCode).toBe(2); // Plain prose with pattern = block
    expect(result.stderr.toString()).toContain('BLOCKED');
  });
});
