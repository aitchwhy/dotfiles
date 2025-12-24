/**
 * Memories Generator
 *
 * Generates memories.md from the MEMORIES constant.
 * Output: human-readable markdown for Claude context.
 */

import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import { Effect } from 'effect';
import { MEMORIES, MEMORY_COUNTS } from '../memories';
import type { Memory, MemoryCategory } from '../memories/schemas';

const CATEGORY_ORDER: readonly MemoryCategory[] = ['principle', 'constraint', 'pattern', 'gotcha'];

const CATEGORY_DESCRIPTIONS: Record<MemoryCategory, string> = {
  principle: 'Guiding philosophies (highest priority)',
  constraint: 'Hard rules that MUST be followed',
  pattern: 'Reusable solutions',
  gotcha: 'Pitfalls to avoid',
};

const formatMemory = (memory: Memory): string => {
  const lines = [`### ${memory.title}`, '', memory.content];
  if (memory.verified) {
    lines.push('', `*Verified: ${memory.verified}*`);
  }
  return lines.join('\n');
};

const formatCategory = (category: MemoryCategory): string => {
  const memories = MEMORIES.filter((m) => m.category === category);
  const header = `## ${category.charAt(0).toUpperCase() + category.slice(1)}s`;
  const description = `*${CATEGORY_DESCRIPTIONS[category]}*`;
  const content = memories.map(formatMemory).join('\n\n');

  return [header, '', description, '', content].join('\n');
};

const generateMarkdown = (): string => {
  const header = [
    '# Engineering Memories',
    '',
    'Staff-to-Principal level craft knowledge.',
    'Flat list of patterns, constraints, and gotchas.',
    '',
    `**Total**: ${MEMORY_COUNTS.total} memories`,
    `- Principles: ${MEMORY_COUNTS.principle}`,
    `- Constraints: ${MEMORY_COUNTS.constraint}`,
    `- Patterns: ${MEMORY_COUNTS.pattern}`,
    `- Gotchas: ${MEMORY_COUNTS.gotcha}`,
    '',
    '---',
    '',
  ].join('\n');

  const categories = CATEGORY_ORDER.map(formatCategory).join('\n\n---\n\n');

  return header + categories + '\n';
};

export const generateMemoriesFile = (outDir: string) =>
  Effect.gen(function* () {
    const markdown = generateMarkdown();
    const filePath = path.join(outDir, 'memories.md');

    yield* Effect.tryPromise(() => fs.writeFile(filePath, markdown));

    yield* Effect.log(`Generated: ${filePath} (${MEMORY_COUNTS.total} memories)`);
    return filePath;
  });
