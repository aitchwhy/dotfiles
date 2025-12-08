#!/usr/bin/env bun
/**
 * Semantic Commit Sentinel - Proposes conventional commits for uncommitted changes
 *
 * Trigger: Stop
 * Mode: Suggest only (non-blocking)
 *
 * Analyzes git diff to detect semantic clusters of related changes,
 * then proposes a conventional commit message.
 */

import { execSync } from 'node:child_process';

interface HookInput {
  hook_event_name: string;
  session_id: string;
  cwd?: string;
}

interface HookOutput {
  continue: boolean;
  additionalContext?: string;
}

interface FileChange {
  path: string;
  directory: string;
  filename: string;
  isTest: boolean;
  isConfig: boolean;
  isDoc: boolean;
}

/**
 * Infer commit type from file changes
 */
function inferCommitType(files: FileChange[]): string {
  const allTests = files.every((f) => f.isTest);
  const allDocs = files.every((f) => f.isDoc);
  const allConfigs = files.every((f) => f.isConfig);
  const hasTests = files.some((f) => f.isTest);

  if (allTests) return 'test';
  if (allDocs) return 'docs';
  if (allConfigs) return 'chore';

  // If we have source + test files, it's likely a feature
  if (hasTests) return 'feat';

  return 'feat';
}

/**
 * Infer scope from file paths
 */
function inferScope(files: FileChange[]): string {
  // Get unique directories
  const dirs = [...new Set(files.map((f) => f.directory))];

  if (dirs.length === 1 && dirs[0]) {
    const dir = dirs[0];
    // Extract meaningful scope from path
    const parts = dir.split('/').filter(Boolean);
    if (parts.includes('hooks')) return 'hooks';
    if (parts.includes('layers')) return 'layers';
    if (parts.includes('generators')) return 'gen';
    if (parts.includes('src')) return parts[parts.length - 1] || 'src';
    return parts[parts.length - 1] || 'root';
  }

  // Multiple directories
  return 'root';
}

/**
 * Generate commit message from file changes
 */
function generateCommitMessage(files: FileChange[]): string {
  const type = inferCommitType(files);
  const scope = inferScope(files);

  // Generate description from filenames
  const names = files.map((f) => f.filename.replace(/\.(ts|tsx|js|jsx|test|spec)$/g, ''));
  const uniqueNames = [...new Set(names)].slice(0, 3);

  let description: string;
  if (files.length === 1) {
    description = `update ${uniqueNames[0]}`;
  } else if (uniqueNames.length <= 3) {
    description = `update ${uniqueNames.join(', ')}`;
  } else {
    description = `update ${files.length} files`;
  }

  return `${type}(${scope}): ${description}`;
}

/**
 * Parse git diff output to get changed files
 */
function parseGitDiff(diffOutput: string): FileChange[] {
  const files: FileChange[] = [];

  for (const line of diffOutput.split('\n')) {
    const path = line.trim();
    if (!path) continue;

    const parts = path.split('/');
    const filename = parts[parts.length - 1] || path;
    const directory = parts.slice(0, -1).join('/');

    files.push({
      path,
      directory,
      filename,
      isTest: /\.(test|spec)\.(ts|tsx|js|jsx)$/.test(filename),
      isConfig: /\.(json|yaml|yml|toml|nix)$/.test(filename) || filename.startsWith('.'),
      isDoc: /\.(md|mdx|txt|rst)$/.test(filename),
    });
  }

  return files;
}

async function main(): Promise<void> {
  // Parse input from stdin
  let input: HookInput;
  try {
    const rawInput = await Bun.stdin.text();
    if (!rawInput.trim()) {
      output({ continue: true });
      return;
    }
    input = JSON.parse(rawInput);
  } catch {
    output({ continue: true });
    return;
  }

  // Only run on Stop
  if (input.hook_event_name !== 'Stop') {
    output({ continue: true });
    return;
  }

  const cwd = input.cwd || process.cwd();

  // Check for uncommitted changes
  let diffOutput: string;
  try {
    // Get both staged and unstaged changes
    const staged = execSync('git diff --cached --name-only', { cwd, encoding: 'utf-8' }).trim();
    const unstaged = execSync('git diff --name-only', { cwd, encoding: 'utf-8' }).trim();

    // Combine and dedupe
    const allFiles = [...new Set([...staged.split('\n'), ...unstaged.split('\n')])].filter(Boolean);
    diffOutput = allFiles.join('\n');
  } catch {
    // Not a git repo or git command failed
    output({ continue: true });
    return;
  }

  // No changes
  if (!diffOutput.trim()) {
    output({ continue: true });
    return;
  }

  // Parse changes and generate commit message
  const files = parseGitDiff(diffOutput);
  if (files.length === 0) {
    output({ continue: true });
    return;
  }

  const commitMessage = generateCommitMessage(files);

  // Build suggestion
  const fileList = files.map((f) => `  - ${f.path}`).join('\n');
  const suggestion = `
📝 Proposed commit for ${files.length} changed file(s):

${fileList}

Suggested commit message:
\`\`\`
${commitMessage}
\`\`\`

To commit: git add -A && git commit -m "${commitMessage}"
`.trim();

  output({
    continue: true,
    additionalContext: suggestion,
  });
}

function output(result: HookOutput): void {
  console.log(JSON.stringify(result));
}

main().catch(() => {
  output({ continue: true });
});
