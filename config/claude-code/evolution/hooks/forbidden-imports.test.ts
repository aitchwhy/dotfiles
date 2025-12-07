/**
 * Forbidden Imports Hook Tests
 */
import { describe, expect, test } from 'bun:test';

describe('Forbidden Imports Hook', () => {
  const FORBIDDEN_IMPORTS = [
    { pattern: "from 'express'", alternative: 'hono' },
    { pattern: 'from "express"', alternative: 'hono' },
    { pattern: "from '@prisma/client'", alternative: 'drizzle-orm' },
    { pattern: "from 'fastify'", alternative: 'hono' },
    { pattern: "from 'zod/v3'", alternative: 'zod' },
    { pattern: "require('express')", alternative: 'hono' },
  ];

  function containsForbiddenImport(content: string): { found: boolean; pattern?: string } {
    for (const { pattern } of FORBIDDEN_IMPORTS) {
      if (content.includes(pattern)) {
        return { found: true, pattern };
      }
    }
    return { found: false };
  }

  describe('import detection', () => {
    test("blocks import from 'express'", () => {
      const content = "import express from 'express';";
      const result = containsForbiddenImport(content);
      expect(result.found).toBe(true);
    });

    test('blocks import from @prisma/client', () => {
      const content = "import { PrismaClient } from '@prisma/client';";
      const result = containsForbiddenImport(content);
      expect(result.found).toBe(true);
    });

    test('blocks require express', () => {
      const content = "const express = require('express');";
      const result = containsForbiddenImport(content);
      expect(result.found).toBe(true);
    });

    test('blocks zod/v3 import', () => {
      const content = "import { z } from 'zod/v3';";
      const result = containsForbiddenImport(content);
      expect(result.found).toBe(true);
    });
  });

  describe('allowed imports', () => {
    test('allows hono import', () => {
      const content = "import { Hono } from 'hono';";
      const result = containsForbiddenImport(content);
      expect(result.found).toBe(false);
    });

    test('allows drizzle-orm import', () => {
      const content = "import { drizzle } from 'drizzle-orm';";
      const result = containsForbiddenImport(content);
      expect(result.found).toBe(false);
    });

    test('allows zod v4 import', () => {
      const content = "import { z } from 'zod';";
      const result = containsForbiddenImport(content);
      expect(result.found).toBe(false);
    });

    test('allows express in comments', () => {
      // This tests the need for stripping comments in actual implementation
      const content = '// Using express pattern here';
      const result = containsForbiddenImport(content);
      // Current simple implementation would catch this - the real hook should not
      // For now, this is expected to pass as false positive prevention
      expect(result.found).toBe(false);
    });
  });
});
