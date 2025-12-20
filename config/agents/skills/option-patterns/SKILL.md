---
name: option-patterns
description: "Option<T> patterns to eliminate null virus. Explicit absence modeling."
allowed-tools: Read, Write, Edit
token-budget: 1200
version: 1.0.0
---

# Option Patterns

## The Null Virus

```typescript
const phone = user.phone ?? null;        // null spreads
const carrier = getCarrier(phone) ?? null; // spreads more
```

## Option: Explicit Absence

```typescript
import { Option } from "effect";

// Convert at boundary
const phone: Option.Option<string> = Option.fromNullable(user.phoneNumber);

// Pattern match - compiler enforces both cases
const display = Option.match(phone, {
  onNone: () => "No phone",
  onSome: (p) => `Phone: ${p}`,
});

// Get with fallback
const phoneOrDefault = Option.getOrElse(phone, () => "N/A");

// For API responses (JSON needs null, not Option)
const apiPhone = Option.getOrNull(phone); // string | null
```

## Schema Integration

```typescript
import { Schema } from "effect";

const User = Schema.Struct({
  id: Schema.String,
  // nullable API field -> Option in domain
  phone: Schema.OptionFromNullOr(Schema.String),
});

type User = typeof User.Type;
// { id: string; phone: Option<string> }
```

## Domain Rules

| Pattern | Status | Replacement |
|---------|--------|-------------|
| `x ?? null` | BANNED | `Option.fromNullable(x)` |
| `T \| null` | BANNED | `Option<T>` |
| `if (x === null)` | BANNED | `Option.match` |
| `x!` | BANNED | Parse at boundary |

## Boundaries

```typescript
// INPUT: nullable -> Option
const phone = Option.fromNullable(request.body.phone);

// OUTPUT: Option -> nullable for JSON
const response = { phone: Option.getOrNull(user.phone) };
```
