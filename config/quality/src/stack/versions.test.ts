/**
 * Stack versions tests
 *
 * Validates that the STACK object is well-formed
 * and helper functions work correctly.
 */
import { describe, expect, test } from 'bun:test';
import { Either } from 'effect';
import { STACK, getNpmVersion, getNpmVersions, isVersionMatch, getDrift, validateStack } from './versions';

describe('Stack Versions', () => {
  test('STACK has required sections', () => {
    expect(STACK.meta).toBeDefined();
    expect(STACK.runtime).toBeDefined();
    expect(STACK.frontend).toBeDefined();
    expect(STACK.backend).toBeDefined();
    expect(STACK.infra).toBeDefined();
    expect(STACK.testing).toBeDefined();
    expect(STACK.npm).toBeDefined();
  });

  test('validateStack returns Right for valid STACK', () => {
    const result = validateStack();
    expect(Either.isRight(result)).toBe(true);
  });

  test('getNpmVersion returns correct version', () => {
    expect(getNpmVersion('typescript')).toBe(STACK.npm.typescript);
    expect(getNpmVersion('effect')).toBe(STACK.npm.effect);
  });

  test('getNpmVersions returns all npm versions', () => {
    const versions = getNpmVersions();
    expect(versions['typescript']).toBe(STACK.npm.typescript);
    expect(Object.keys(versions).length).toBeGreaterThan(0);
  });

  test('isVersionMatch returns true for matching versions', () => {
    expect(isVersionMatch('typescript', STACK.npm.typescript)).toBe(true);
  });

  test('isVersionMatch returns false for mismatched versions', () => {
    expect(isVersionMatch('typescript', '0.0.0')).toBe(false);
  });

  test('isVersionMatch returns true for unknown packages', () => {
    expect(isVersionMatch('unknown-package', '1.0.0')).toBe(true);
  });

  test('getDrift returns empty array for matching deps', () => {
    const drift = getDrift({ typescript: STACK.npm.typescript });
    expect(drift).toEqual([]);
  });

  test('getDrift returns drift for mismatched deps', () => {
    const drift = getDrift({ typescript: '0.0.0' });
    expect(drift).toHaveLength(1);
    expect(drift[0]?.pkg).toBe('typescript');
    expect(drift[0]?.expected).toBe(STACK.npm.typescript);
    expect(drift[0]?.actual).toBe('0.0.0');
  });

  test('runtime has pnpm instead of bun', () => {
    expect(STACK.runtime.pnpm).toBeDefined();
    expect((STACK.runtime as Record<string, unknown>)['bun']).toBeUndefined();
  });

  test('infra has docker-compose instead of process-compose', () => {
    expect(STACK.infra['docker-compose']).toBeDefined();
    expect((STACK.infra as Record<string, unknown>)['process-compose']).toBeUndefined();
  });
});
