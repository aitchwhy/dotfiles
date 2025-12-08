/**
 * Clean Code Skill Definition
 *
 * Clean code patterns for Nix and TypeScript.
 * Migrated from: config/claude-code/skills/clean-code/SKILL.md
 */
import type { SystemSkill } from '@/schema'

export const cleanCodeSkill: SystemSkill = {
  name: 'clean-code' as SystemSkill['name'],
  description:
    'Clean code patterns for Nix and TypeScript. Explicit imports, Result types, function size limits. Apply to dotfiles and TypeScript projects.',
  allowedTools: ['Read', 'Write', 'Edit', 'Grep', 'Glob'] as SystemSkill['allowedTools'],

  sections: [
    // =========================================================================
    // Nix-Specific Patterns
    // =========================================================================
    {
      title: 'Nix-Specific Patterns',
      patterns: [
        {
          title: 'Explicit Library Imports (Never `with lib;`)',
          description:
            'The `with lib;` pattern pollutes scope and hides where functions come from.',
          annotation: 'info',
          language: 'nix',
          code: `# Bad: implicit scope pollution
{ config, lib, ... }:
with lib;
{
  options.foo = mkOption { ... };
  config = mkIf config.foo.enable { ... };
}

# Good: explicit imports, clear provenance
{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkOption mkIf types;
in
{
  options.foo = mkOption { ... };
  config = mkIf config.foo.enable { ... };
}`,
        },
        {
          title: 'Only Import What You Use',
          description: "Don't inherit functions you don't need.",
          annotation: 'do',
          language: 'nix',
          code: `# Bad: importing everything "just in case"
let
  inherit (lib) mkEnableOption mkOption mkIf mkMerge types optionals concatStrings;
in
# ... only uses mkEnableOption and mkIf

# Good: minimal imports
let
  inherit (lib) mkEnableOption mkIf;
in`,
        },
        {
          title: 'Use `lib.` Prefix for Rare Functions',
          description: 'For functions used only once or twice, use the prefix directly.',
          annotation: 'do',
          language: 'nix',
          code: `let
  inherit (lib) mkIf mkEnableOption;
in
{
  # Used once - prefix is fine
  environment.systemPackages = lib.optionals config.services.foo.enable [ pkgs.bar ];

  # Used multiple times - inherited above
  config = mkIf config.services.foo.enable { ... };
}`,
        },
        {
          title: 'Module Structure',
          description: 'Standard Nix module layout: options first, then config.',
          annotation: 'do',
          language: 'nix',
          code: `{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.myModule;
in
{
  # 1. Options first
  options.myModule = {
    enable = mkEnableOption "my module";
    # ... other options
  };

  # 2. Config second
  config = mkIf cfg.enable {
    # implementation
  };
}`,
        },
      ],
    },

    // =========================================================================
    // TypeScript Clean Code
    // =========================================================================
    {
      title: 'TypeScript Clean Code',
      patterns: [
        {
          title: 'Function Size Limits',
          description: 'Functions should do one thing and be < 20 lines.',
          annotation: 'info',
          language: 'typescript',
          code: `// Bad: monolithic function
async function processOrder(order: Order): Promise<Result<ProcessedOrder, Error>> {
  // 50+ lines of validation, transformation, side effects
}

// Good: decomposed into single-responsibility functions
async function processOrder(order: Order): Promise<Result<ProcessedOrder, Error>> {
  const validated = validateOrder(order);
  if (!validated.ok) return validated;

  const enriched = await enrichWithCustomerData(validated.data);
  if (!enriched.ok) return enriched;

  return calculateTotals(enriched.data);
}

function validateOrder(order: Order): Result<ValidatedOrder, ValidationError> {
  // 5-10 lines
}

async function enrichWithCustomerData(order: ValidatedOrder): Promise<Result<EnrichedOrder, Error>> {
  // 5-10 lines
}

function calculateTotals(order: EnrichedOrder): Result<ProcessedOrder, Error> {
  // 5-10 lines
}`,
        },
        {
          title: 'Semantic Naming',
          description: 'Names should reveal intent.',
          annotation: 'do',
          language: 'typescript',
          code: `// Bad: cryptic names
const d = new Date();
const u = users.filter(x => x.a > 0);
for (let i = 0; i < items.length; i++) { ... }

// Good: semantic names
const orderCreatedAt = new Date();
const activeUsers = users.filter(user => user.activityCount > 0);
for (let itemIdx = 0; itemIdx < items.length; itemIdx++) { ... }`,
        },
        {
          title: 'Magic Numbers as Expressions',
          description: 'Use self-documenting expressions instead of unexplained constants.',
          annotation: 'do',
          language: 'typescript',
          code: `// Bad: unexplained constants
const timeout = 86400000;
const maxRetries = 3;

// Good: self-documenting expressions
const ONE_DAY_MS = 24 * 60 * 60 * 1000;
const timeout = ONE_DAY_MS;

// Or inline for clarity
const sessionTimeout = 24 * 60 * 60 * 1000; // 24 hours in milliseconds`,
        },
        {
          title: 'No Commented-Out Code',
          description: 'Delete it. Git has history.',
          annotation: 'dont',
          language: 'typescript',
          code: `// Bad: graveyard of dead code
function calculatePrice(item: Item) {
  // const oldPrice = item.basePrice * 1.1;
  // return oldPrice + tax;
  // TODO: revert if new pricing fails
  return item.basePrice * 1.15 + tax;
}

// Good: clean implementation
function calculatePrice(item: Item) {
  const PRICE_MULTIPLIER = 1.15;
  return item.basePrice * PRICE_MULTIPLIER + tax;
}`,
        },
        {
          title: 'Comments Explain "Why", Not "What"',
          description: 'Code shows what; comments explain why.',
          annotation: 'info',
          language: 'typescript',
          code: `// Bad: describes what code does (obvious from code)
// Loop through users and check if active
for (const user of users) {
  if (user.isActive) { ... }
}

// Good: explains why this approach was chosen
// Use in-memory filtering instead of DB query because
// the user list is small (<100) and already cached
const activeUsers = users.filter(user => user.isActive);`,
        },
        {
          title: 'Readonly by Default',
          description: 'Use readonly to prevent accidental mutations.',
          annotation: 'do',
          language: 'typescript',
          code: `// Bad: mutable data invites bugs
interface User {
  name: string;
  roles: string[];
}

// Good: immutable by default
interface User {
  readonly name: string;
  readonly roles: readonly string[];
}

// For function parameters
function processUsers(users: readonly User[]): ProcessedUser[] {
  // users.push(x); // Type error: cannot modify readonly array
  return users.map(transform);
}`,
        },
        {
          title: 'Early Returns Over Nesting',
          description: 'Use guard clauses to reduce nesting.',
          annotation: 'do',
          language: 'typescript',
          code: `// Bad: deeply nested conditions
function processRequest(req: Request) {
  if (req.user) {
    if (req.user.isActive) {
      if (req.user.hasPermission('write')) {
        return doWork(req);
      } else {
        return Err('No permission');
      }
    } else {
      return Err('User inactive');
    }
  } else {
    return Err('Not authenticated');
  }
}

// Good: guard clauses with early returns
function processRequest(req: Request) {
  if (!req.user) return Err('Not authenticated');
  if (!req.user.isActive) return Err('User inactive');
  if (!req.user.hasPermission('write')) return Err('No permission');

  return doWork(req);
}`,
        },
      ],
    },

    // =========================================================================
    // File Organization
    // =========================================================================
    {
      title: 'File Organization',
      patterns: [
        {
          title: 'One Concept Per File',
          description: 'Avoid kitchen-sink modules.',
          annotation: 'do',
          language: 'text',
          code: `# Bad: kitchen sink modules
src/
  utils.ts        # 500+ lines of random helpers
  types.ts        # Every type in the project

# Good: focused modules
src/
  lib/
    result.ts     # Result type + utilities
    date.ts       # Date formatting helpers
    validation.ts # Validation utilities
  types/
    user.ts       # User-related types
    order.ts      # Order-related types`,
        },
        {
          title: 'Barrel Exports (Use Sparingly)',
          description: 'Re-exports for clean imports, but use judiciously.',
          annotation: 'info',
          language: 'typescript',
          code: `// src/lib/index.ts - re-exports for clean imports
export { Result, Ok, Err, isOk, isErr } from './result';
export { formatDate, parseDate } from './date';

// Consumer gets clean imports
import { Result, Ok, formatDate } from '@/lib';`,
        },
      ],
    },
  ],
}
