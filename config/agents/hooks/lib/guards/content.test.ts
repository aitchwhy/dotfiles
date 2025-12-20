import { describe, it, expect } from 'bun:test';
import { runContentGuards } from './content';

describe('Content Guards', () => {
  const testFile = '/src/test.ts';

  describe('Guard 40: Type Assertions', () => {
    it('blocks as Type', async () => {
      const result = await runContentGuards('const x = data as User;', testFile);
      expect(result.ok).toBe(false);
      expect(result.error).toContain('Guard 40');
    });

    it('blocks as { ... }', async () => {
      const result = await runContentGuards('const x = data as { foo: string };', testFile);
      expect(result.ok).toBe(false);
      expect(result.error).toContain('Guard 40');
    });

    it('blocks as Generic<T>', async () => {
      const result = await runContentGuards('const x = data as Array<string>;', testFile);
      expect(result.ok).toBe(false);
      expect(result.error).toContain('Guard 40');
    });

    it('allows as const', async () => {
      const result = await runContentGuards('const x = [1, 2] as const;', testFile);
      expect(result.ok).toBe(true);
    });

    it('allows as unknown', async () => {
      const result = await runContentGuards('const x = data as unknown;', testFile);
      expect(result.ok).toBe(true);
    });

    it('allows as never', async () => {
      const result = await runContentGuards('const x = data as never;', testFile);
      expect(result.ok).toBe(true);
    });
  });

  describe('Guard 41: Null Propagation', () => {
    it('blocks ?? null', async () => {
      const result = await runContentGuards('const x = foo ?? null;', testFile);
      expect(result.ok).toBe(false);
      expect(result.error).toContain('Guard 41');
    });

    it('blocks ?? null in object', async () => {
      const result = await runContentGuards('return { phone: user.phone ?? null };', testFile);
      expect(result.ok).toBe(false);
      expect(result.error).toContain('Guard 41');
    });

    it('blocks ?? null in array', async () => {
      const result = await runContentGuards('const arr = [foo ?? null];', testFile);
      expect(result.ok).toBe(false);
      expect(result.error).toContain('Guard 41');
    });

    it('allows ?? defaultValue', async () => {
      const result = await runContentGuards('const x = foo ?? "default";', testFile);
      expect(result.ok).toBe(true);
    });

    it('allows ?? undefined', async () => {
      const result = await runContentGuards('const x = foo ?? undefined;', testFile);
      expect(result.ok).toBe(true);
    });
  });

  describe('Guard 42: Date Construction', () => {
    it('blocks new Date()', async () => {
      const result = await runContentGuards('const now = new Date();', testFile);
      expect(result.ok).toBe(false);
      expect(result.error).toContain('Guard 42');
    });

    it('blocks Date.now()', async () => {
      const result = await runContentGuards('const ts = Date.now();', testFile);
      expect(result.ok).toBe(false);
      expect(result.error).toContain('Guard 42');
    });

    it('allows new Date(timestamp)', async () => {
      const result = await runContentGuards('const d = new Date(1234567890);', testFile);
      expect(result.ok).toBe(true);
    });

    it('allows new Date(string)', async () => {
      const result = await runContentGuards('const d = new Date("2024-01-01");', testFile);
      expect(result.ok).toBe(true);
    });

    it('allows in schema files', async () => {
      const result = await runContentGuards('const now = new Date();', '/src/user.schema.ts');
      expect(result.ok).toBe(true);
    });

    it('allows in schemas directory', async () => {
      const result = await runContentGuards('const now = new Date();', '/src/schemas/date.ts');
      expect(result.ok).toBe(true);
    });
  });

  describe('Guard 43: Try/Catch', () => {
    it('blocks try/catch in domain code', async () => {
      const result = await runContentGuards('try { doThing(); } catch (e) {}', testFile);
      expect(result.ok).toBe(false);
      expect(result.error).toContain('Guard 43');
    });

    it('allows try/catch in server.ts', async () => {
      const result = await runContentGuards('try { doThing(); } catch (e) {}', '/src/server.ts');
      expect(result.ok).toBe(true);
    });

    it('allows try/catch in main.ts', async () => {
      const result = await runContentGuards('try { doThing(); } catch (e) {}', '/src/main.ts');
      expect(result.ok).toBe(true);
    });

    it('allows Effect.try pattern', async () => {
      const result = await runContentGuards('Effect.try(() => riskyThing())', testFile);
      expect(result.ok).toBe(true);
    });

    it('allows Effect.tryPromise pattern', async () => {
      const result = await runContentGuards('Effect.tryPromise({ try: () => fetch() })', testFile);
      expect(result.ok).toBe(true);
    });
  });

  describe('Guard 44: Raw Fetch', () => {
    it('blocks fetch()', async () => {
      const result = await runContentGuards('const res = await fetch("/api");', testFile);
      expect(result.ok).toBe(false);
      expect(result.error).toContain('Guard 44');
    });

    it('blocks window.fetch()', async () => {
      const result = await runContentGuards('const res = window.fetch("/api");', testFile);
      expect(result.ok).toBe(false);
      expect(result.error).toContain('Guard 44');
    });

    it('blocks globalThis.fetch()', async () => {
      const result = await runContentGuards('const res = globalThis.fetch("/api");', testFile);
      expect(result.ok).toBe(false);
      expect(result.error).toContain('Guard 44');
    });
  });

  describe('Guard 48: Non-Null Assertion', () => {
    it('blocks x!', async () => {
      const result = await runContentGuards('const x = foo!;', testFile);
      expect(result.ok).toBe(false);
      expect(result.error).toContain('Guard 48');
    });

    it('blocks foo.bar!', async () => {
      const result = await runContentGuards('const x = foo.bar!.baz;', testFile);
      expect(result.ok).toBe(false);
      expect(result.error).toContain('Guard 48');
    });

    it('blocks array[0]!', async () => {
      const result = await runContentGuards('const x = arr[0]!;', testFile);
      expect(result.ok).toBe(false);
      expect(result.error).toContain('Guard 48');
    });
  });

  describe('Existing Guards', () => {
    describe('Guard 4: Forbidden Imports', () => {
      it('blocks express', async () => {
        const result = await runContentGuards('import express from "express";', testFile);
        expect(result.ok).toBe(false);
        expect(result.error).toContain('Guard 4');
      });

      it('blocks hono', async () => {
        const result = await runContentGuards('import { Hono } from "hono";', testFile);
        expect(result.ok).toBe(false);
        expect(result.error).toContain('Guard 4');
      });

      it('blocks pg driver', async () => {
        const result = await runContentGuards('import { Pool } from "pg";', testFile);
        expect(result.ok).toBe(false);
        expect(result.error).toContain('Guard 4');
      });
    });

    describe('Guard 5: Any Type', () => {
      it('blocks : any', async () => {
        const result = await runContentGuards('const x: any = 1;', testFile);
        expect(result.ok).toBe(false);
        expect(result.error).toContain('Guard 5');
      });

      it('blocks as any', async () => {
        const result = await runContentGuards('const x = foo as any;', testFile);
        expect(result.ok).toBe(false);
        expect(result.error).toContain('Guard 5');
      });
    });

    describe('Guard 6: z.infer', () => {
      it('blocks z.infer<>', async () => {
        const result = await runContentGuards('type User = z.infer<typeof UserSchema>;', testFile);
        expect(result.ok).toBe(false);
        expect(result.error).toContain('Guard 6');
      });
    });

    describe('Guard 7: No Mocks', () => {
      it('blocks jest.mock', async () => {
        const result = await runContentGuards('jest.mock("./module");', testFile);
        expect(result.ok).toBe(false);
        expect(result.error).toContain('Guard 7');
      });

      it('blocks vi.mock', async () => {
        const result = await runContentGuards('vi.mock("./module");', testFile);
        expect(result.ok).toBe(false);
        expect(result.error).toContain('Guard 7');
      });
    });

    describe('Guard 26: Console', () => {
      it('blocks console.log', async () => {
        const result = await runContentGuards('console.log("test");', testFile);
        expect(result.ok).toBe(false);
        expect(result.error).toContain('Guard 26');
      });
    });
  });

  describe('Edge Cases', () => {
    it('skips excluded paths (test files)', async () => {
      const result = await runContentGuards('const x = data as User;', '/src/test.test.ts');
      expect(result.ok).toBe(true);
    });

    it('skips non-TypeScript files', async () => {
      const result = await runContentGuards('const x = data as User;', '/src/file.json');
      expect(result.ok).toBe(true);
    });

    it('handles empty content', async () => {
      const result = await runContentGuards('', testFile);
      expect(result.ok).toBe(true);
    });

    it('handles undefined content', async () => {
      const result = await runContentGuards(undefined, testFile);
      expect(result.ok).toBe(true);
    });
  });
});
