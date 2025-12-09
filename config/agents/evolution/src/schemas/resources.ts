/**
 * Resource Schemas for Claude Code Configuration
 *
 * Zod schemas for validating:
 * - Skills (SKILL.md frontmatter)
 * - Commands (command.md frontmatter)
 * - Agents (agent.md frontmatter)
 * - settings.json structure
 */

import { z } from 'zod';

// ============================================================================
// YAML Frontmatter Schemas
// ============================================================================

/**
 * Skill YAML frontmatter schema
 * Skills are defined in /skills/<name>/SKILL.md
 */
export const SkillFrontmatterSchema = z.object({
  name: z.string().optional(),
  description: z.string().min(1, 'Description is required'),
  'allowed-tools': z.string().optional(),
});

export type SkillFrontmatter = z.infer<typeof SkillFrontmatterSchema>;

/**
 * Command YAML frontmatter schema
 * Commands are defined in /commands/<name>.md
 */
export const CommandFrontmatterSchema = z.object({
  description: z.string().min(1, 'Description is required'),
  'allowed-tools': z.string().optional(),
});

export type CommandFrontmatter = z.infer<typeof CommandFrontmatterSchema>;

/**
 * Agent YAML frontmatter schema
 * Agents are defined in /agents/<name>.md
 */
export const AgentFrontmatterSchema = z.object({
  name: z.string().optional(),
  description: z.string().min(1, 'Description is required'),
  'allowed-tools': z.string().optional(),
});

export type AgentFrontmatter = z.infer<typeof AgentFrontmatterSchema>;

// ============================================================================
// Settings.json Schemas
// ============================================================================

/**
 * Permission rule - patterns for allow/deny lists
 */
export const PermissionRuleSchema = z.string().min(1);

/**
 * Permissions section of settings.json
 */
export const PermissionsSchema = z.object({
  allow: z.array(PermissionRuleSchema),
  deny: z.array(PermissionRuleSchema),
});

export type Permissions = z.infer<typeof PermissionsSchema>;

/**
 * Individual hook definition
 */
export const HookDefinitionSchema = z.object({
  type: z.literal('command'),
  command: z.string().min(1, 'Hook command is required'),
  timeout: z.number().positive().optional(),
});

export type HookDefinition = z.infer<typeof HookDefinitionSchema>;

/**
 * Hook matcher with its hooks array
 * Note: matcher is optional for SessionStart/Stop hooks (they run unconditionally)
 */
export const HookMatcherSchema = z.object({
  matcher: z.string().min(1).optional(),
  hooks: z.array(HookDefinitionSchema).min(1, 'At least one hook is required'),
});

export type HookMatcher = z.infer<typeof HookMatcherSchema>;

/**
 * Hooks section of settings.json
 */
export const HooksSchema = z.object({
  PreToolUse: z.array(HookMatcherSchema).optional(),
  PostToolUse: z.array(HookMatcherSchema).optional(),
  SessionStart: z.array(HookMatcherSchema).optional(),
  Stop: z.array(HookMatcherSchema).optional(),
});

export type Hooks = z.infer<typeof HooksSchema>;

/**
 * Complete settings.json schema
 */
export const SettingsSchema = z.object({
  permissions: PermissionsSchema,
  hooks: HooksSchema,
});

export type Settings = z.infer<typeof SettingsSchema>;

// ============================================================================
// Validation Helpers
// ============================================================================

/**
 * Parse YAML frontmatter from markdown content
 * Returns the frontmatter object and the remaining content
 */
export function parseFrontmatter(content: string): {
  frontmatter: Record<string, unknown>;
  body: string;
} {
  const match = content.match(/^---\n([\s\S]*?)\n---\n?([\s\S]*)/);
  if (!match) {
    return { frontmatter: {}, body: content };
  }

  const [, yamlContent, body] = match;
  const frontmatter: Record<string, unknown> = {};

  // Simple YAML parser for frontmatter (key: value pairs)
  for (const line of (yamlContent || '').split('\n')) {
    const colonIndex = line.indexOf(':');
    if (colonIndex === -1) continue;

    const key = line.slice(0, colonIndex).trim();
    let value: string | string[] = line.slice(colonIndex + 1).trim();

    // Remove quotes if present
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    // Handle arrays (simple case: comma-separated in same line)
    if (value.startsWith('[') && value.endsWith(']')) {
      value = value
        .slice(1, -1)
        .split(',')
        .map((v) => v.trim());
    }

    frontmatter[key] = value;
  }

  return { frontmatter, body: body || '' };
}

/**
 * Validate a skill file
 */
export function validateSkill(content: string) {
  const { frontmatter } = parseFrontmatter(content);
  return SkillFrontmatterSchema.safeParse(frontmatter);
}

/**
 * Validate a command file
 */
export function validateCommand(content: string) {
  const { frontmatter } = parseFrontmatter(content);
  return CommandFrontmatterSchema.safeParse(frontmatter);
}

/**
 * Validate an agent file
 */
export function validateAgent(content: string) {
  const { frontmatter } = parseFrontmatter(content);
  return AgentFrontmatterSchema.safeParse(frontmatter);
}

/**
 * Validate settings.json content
 */
export function validateSettings(content: unknown) {
  return SettingsSchema.safeParse(content);
}

// ============================================================================
// Permission Pattern Validation
// ============================================================================

/**
 * Valid tool names that can appear in permission patterns
 */
export const VALID_TOOL_NAMES = [
  'Read',
  'Write',
  'Edit',
  'MultiEdit',
  'Bash',
  'Grep',
  'Glob',
  'Task',
  'WebFetch',
  'WebSearch',
  'TodoWrite',
  'AskUserQuestion',
  'NotebookEdit',
] as const;

/**
 * Validate a permission pattern syntax
 */
export function isValidPermissionPattern(pattern: string): boolean {
  // Simple patterns: ToolName or ToolName(glob)
  const simpleMatch = pattern.match(/^([A-Za-z]+)(\(.*\))?$/);
  if (!simpleMatch) return false;

  const toolName = simpleMatch[1];
  // Check if it's a known tool name (allowing for future tools)
  return /^[A-Z][a-zA-Z]*$/.test(toolName || '');
}
