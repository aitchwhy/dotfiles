---
name: clean-code
description: Clean code patterns for Nix and TypeScript. Explicit imports, Result types, function size limits. Apply to dotfiles and TypeScript projects.
allowed-tools: Read, Write, Edit, Grep, Glob
---

# Clean Code Patterns

## Nix-Specific Patterns

### Explicit Library Imports (Never `with lib;`)

The `with lib;` pattern pollutes scope and hides where functions come from:

```nix
# Bad: implicit scope pollution
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
}
```

### Only Import What You Use

Don't inherit functions you don't need:

```nix
# Bad: importing everything "just in case"
let
  inherit (lib) mkEnableOption mkOption mkIf mkMerge types optionals concatStrings;
in
# ... only uses mkEnableOption and mkIf

# Good: minimal imports
let
  inherit (lib) mkEnableOption mkIf;
in
```

### Use `lib.` Prefix for Rare Functions

For functions used only once or twice, use the prefix directly:

```nix
let
  inherit (lib) mkIf mkEnableOption;
in
{
  # Used once - prefix is fine
  environment.systemPackages = lib.optionals config.services.foo.enable [ pkgs.bar ];

  # Used multiple times - inherited above
  config = mkIf config.services.foo.enable { ... };
}
```

### Module Structure

```nix
{ config, lib, pkgs, ... }:
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
}
```

## TypeScript Clean Code

### Function Size Limits

Functions should do one thing and be < 20 lines:

```typescript
// Bad: monolithic function
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
}
```

### Semantic Naming

Names should reveal intent:

```typescript
// Bad: cryptic names
const d = new Date();
const u = users.filter(x => x.a > 0);
for (let i = 0; i < items.length; i++) { ... }

// Good: semantic names
const orderCreatedAt = new Date();
const activeUsers = users.filter(user => user.activityCount > 0);
for (let itemIdx = 0; itemIdx < items.length; itemIdx++) { ... }
```

### Magic Numbers as Expressions

```typescript
// Bad: unexplained constants
const timeout = 86400000;
const maxRetries = 3;

// Good: self-documenting expressions
const ONE_DAY_MS = 24 * 60 * 60 * 1000;
const timeout = ONE_DAY_MS;

// Or inline for clarity
const sessionTimeout = 24 * 60 * 60 * 1000; // 24 hours in milliseconds
```

### No Commented-Out Code

Delete it. Git has history:

```typescript
// Bad: graveyard of dead code
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
}
```

### Comments Explain "Why", Not "What"

```typescript
// Bad: describes what code does (obvious from code)
// Loop through users and check if active
for (const user of users) {
  if (user.isActive) { ... }
}

// Good: explains why this approach was chosen
// Use in-memory filtering instead of DB query because
// the user list is small (<100) and already cached
const activeUsers = users.filter(user => user.isActive);
```

### Readonly by Default

```typescript
// Bad: mutable data invites bugs
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
}
```

### Early Returns Over Nesting

```typescript
// Bad: deeply nested conditions
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
}
```

## File Organization

### One Concept Per File

```
# Bad: kitchen sink modules
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
    order.ts      # Order-related types
```

### Barrel Exports (Use Sparingly)

```typescript
// src/lib/index.ts - re-exports for clean imports
export { Result, Ok, Err, isOk, isErr } from './result';
export { formatDate, parseDate } from './date';

// Consumer gets clean imports
import { Result, Ok, formatDate } from '@/lib';
```
