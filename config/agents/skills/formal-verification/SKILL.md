---
name: formal-verification
description: Formal contract generation and verification patterns. Preconditions, postconditions, invariants, and property-based testing.
allowed-tools: Read, Write, Edit, Bash
token-budget: 1500
---

## Philosophy: Prove Before Ship

Every function with side effects or complex logic MUST have:
1. **Preconditions** - What must be true before execution
2. **Postconditions** - What must be true after execution
3. **Invariants** - What must always be true

## Contract Syntax (Effect-TS + Zod)

### Basic Contract Pattern

```typescript
import { Effect, Schema } from 'effect';
import * as z from 'zod/v4';

// 1. Define contract types explicitly
type TransferContract = {
  readonly preconditions: {
    readonly sourceHasSufficientBalance: boolean;
    readonly targetAccountExists: boolean;
    readonly amountIsPositive: boolean;
  };
  readonly postconditions: {
    readonly sourceBalanceDecreased: boolean;
    readonly targetBalanceIncreased: boolean;
    readonly totalBalanceUnchanged: boolean;
  };
};

// 2. Contract-aware function
const transfer = (
  sourceId: AccountId,
  targetId: AccountId,
  amount: Money
): Effect.Effect<TransferResult, TransferError, AccountService> =>
  Effect.gen(function* () {
    // PRECONDITION CHECKS
    const source = yield* AccountService.get(sourceId);
    const target = yield* AccountService.get(targetId);

    yield* Effect.when(
      () => source.balance < amount,
      () => Effect.fail(new InsufficientBalanceError({ sourceId, balance: source.balance, amount }))
    );

    // CAPTURE PRE-STATE for postcondition verification
    const preSourceBalance = source.balance;
    const preTargetBalance = target.balance;
    const preTotalBalance = preSourceBalance + preTargetBalance;

    // EXECUTION
    yield* AccountService.debit(sourceId, amount);
    yield* AccountService.credit(targetId, amount);

    // POSTCONDITION VERIFICATION
    const postSource = yield* AccountService.get(sourceId);
    const postTarget = yield* AccountService.get(targetId);
    const postTotalBalance = postSource.balance + postTarget.balance;

    // INVARIANT: Total balance unchanged
    yield* Effect.when(
      () => postTotalBalance !== preTotalBalance,
      () => Effect.fail(new InvariantViolationError({
        invariant: 'total_balance_unchanged',
        expected: preTotalBalance,
        actual: postTotalBalance
      }))
    );

    return { sourceId, targetId, amount, newSourceBalance: postSource.balance };
  });
```

### Contract Type Definitions

```typescript
// Generic contract type
type Contract<I, O> = {
  readonly preconditions: ReadonlyArray<{
    readonly name: string;
    readonly check: (input: I) => boolean;
    readonly message: string;
  }>;
  readonly postconditions: ReadonlyArray<{
    readonly name: string;
    readonly check: (input: I, output: O) => boolean;
    readonly message: string;
  }>;
  readonly invariants: ReadonlyArray<{
    readonly name: string;
    readonly check: () => boolean;
    readonly message: string;
  }>;
};

// Contract enforcement wrapper
function withContract<I, O, E, R>(
  contract: Contract<I, O>,
  fn: (input: I) => Effect.Effect<O, E, R>
): (input: I) => Effect.Effect<O, E | ContractViolation, R> {
  return (input) =>
    Effect.gen(function* () {
      // Check preconditions
      for (const pre of contract.preconditions) {
        if (!pre.check(input)) {
          return yield* Effect.fail(new PreconditionViolation({
            name: pre.name,
            message: pre.message
          }));
        }
      }

      // Execute
      const output = yield* fn(input);

      // Check postconditions
      for (const post of contract.postconditions) {
        if (!post.check(input, output)) {
          return yield* Effect.fail(new PostconditionViolation({
            name: post.name,
            message: post.message
          }));
        }
      }

      // Check invariants
      for (const inv of contract.invariants) {
        if (!inv.check()) {
          return yield* Effect.fail(new InvariantViolation({
            name: inv.name,
            message: inv.message
          }));
        }
      }

      return output;
    });
}
```

## Property-Based Testing with fast-check

### Basic Property Tests

```typescript
import { test, fc } from '@fast-check/vitest';

// Property: Sorting is idempotent
test.prop([fc.array(fc.integer())])('sort is idempotent', (arr) => {
  const sorted = arr.toSorted((a, b) => a - b);
  const sortedAgain = sorted.toSorted((a, b) => a - b);
  expect(sorted).toEqual(sortedAgain);
});

// Property: Sorting preserves length
test.prop([fc.array(fc.integer())])('sort preserves length', (arr) => {
  const sorted = arr.toSorted((a, b) => a - b);
  expect(sorted.length).toBe(arr.length);
});

// Property: Sorted array is monotonically increasing
test.prop([fc.array(fc.integer())])('sort produces ordered array', (arr) => {
  const sorted = arr.toSorted((a, b) => a - b);
  for (let i = 0; i < sorted.length - 1; i++) {
    expect(sorted[i]).toBeLessThanOrEqual(sorted[i + 1]);
  }
});
```

### Domain-Specific Arbitraries

```typescript
// Custom arbitrary for branded types
const userIdArb = fc.uuid().map(id => UserId(id));
const moneyArb = fc.integer({ min: 1, max: 1_000_000 }).map(n => Money(n));
const emailArb = fc.emailAddress().map(e => ValidEmail(e));

// Arbitrary for domain objects
const userArb = fc.record({
  id: userIdArb,
  email: emailArb,
  balance: moneyArb,
  createdAt: fc.date(),
});

// Property: User creation is reversible
test.prop([userArb])('serialize/deserialize roundtrip', (user) => {
  const json = JSON.stringify(user);
  const parsed = userSchema.parse(JSON.parse(json));
  expect(parsed.id).toBe(user.id);
  expect(parsed.email).toBe(user.email);
});
```

### Algebraic Properties

```typescript
// Monoid laws for string concatenation
test.prop([fc.string(), fc.string(), fc.string()])(
  'string concat is associative',
  (a, b, c) => {
    expect((a + b) + c).toBe(a + (b + c));
  }
);

test.prop([fc.string()])('empty string is identity', (s) => {
  expect('' + s).toBe(s);
  expect(s + '').toBe(s);
});

// Functor laws for Result type
test.prop([fc.integer()])('Result.map identity', (n) => {
  const result = Ok(n);
  const mapped = mapResult(result, x => x);
  expect(mapped).toEqual(result);
});

test.prop([fc.integer()])('Result.map composition', (n) => {
  const f = (x: number) => x + 1;
  const g = (x: number) => x * 2;
  const result = Ok(n);

  const composed = mapResult(result, x => g(f(x)));
  const sequential = mapResult(mapResult(result, f), g);

  expect(composed).toEqual(sequential);
});
```

### Stateful Property Testing

```typescript
// Model-based testing for stateful systems
class AccountModel {
  balance = 0;

  deposit(amount: number) {
    if (amount > 0) this.balance += amount;
  }

  withdraw(amount: number): boolean {
    if (amount > 0 && amount <= this.balance) {
      this.balance -= amount;
      return true;
    }
    return false;
  }
}

// Commands for state machine
const depositCmd = fc.record({
  type: fc.constant('deposit' as const),
  amount: fc.integer({ min: 1, max: 1000 }),
});

const withdrawCmd = fc.record({
  type: fc.constant('withdraw' as const),
  amount: fc.integer({ min: 1, max: 1000 }),
});

const commandArb = fc.oneof(depositCmd, withdrawCmd);

test.prop([fc.array(commandArb, { maxLength: 100 })])(
  'account model matches implementation',
  async (commands) => {
    const model = new AccountModel();
    const real = new Account();

    for (const cmd of commands) {
      if (cmd.type === 'deposit') {
        model.deposit(cmd.amount);
        await real.deposit(cmd.amount);
      } else {
        const modelResult = model.withdraw(cmd.amount);
        const realResult = await real.withdraw(cmd.amount);
        expect(realResult.ok).toBe(modelResult);
      }

      expect(await real.getBalance()).toBe(model.balance);
    }
  }
);
```

## Refinement Types with Zod

### Type-Safe Refinements

```typescript
// TypeScript type is source of truth
type PositiveAmount = number & { readonly __brand: 'PositiveAmount' };
type NonEmptyString = string & { readonly __brand: 'NonEmptyString' };
type ValidEmail = string & { readonly __brand: 'ValidEmail' };
type Percentage = number & { readonly __brand: 'Percentage' };

// Schemas satisfy types (never use z.infer)
const positiveAmountSchema = z.number()
  .positive('Amount must be positive')
  .transform(n => n as PositiveAmount) satisfies z.ZodType<PositiveAmount>;

const nonEmptyStringSchema = z.string()
  .min(1, 'String must not be empty')
  .transform(s => s as NonEmptyString) satisfies z.ZodType<NonEmptyString>;

const validEmailSchema = z.string()
  .email('Invalid email format')
  .transform(s => s as ValidEmail) satisfies z.ZodType<ValidEmail>;

const percentageSchema = z.number()
  .min(0, 'Percentage must be >= 0')
  .max(100, 'Percentage must be <= 100')
  .transform(n => n as Percentage) satisfies z.ZodType<Percentage>;

// Function signatures encode contracts
const createUser = (
  name: NonEmptyString,  // Precondition: name is not empty
  email: ValidEmail      // Precondition: email is valid
): Effect.Effect<User, CreateUserError, UserService> => { /* ... */ };
```

### Dependent Types via Zod Refinement

```typescript
// Order with validated line items
type ValidOrder = {
  readonly items: ReadonlyArray<LineItem>;
  readonly total: PositiveAmount;
};

const orderSchema = z.object({
  items: z.array(lineItemSchema).min(1, 'Order must have at least one item'),
  total: positiveAmountSchema,
}).refine(
  (order) => {
    const calculatedTotal = order.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
    return Math.abs(calculatedTotal - order.total) < 0.01;
  },
  { message: 'Total must match sum of line items' }
) satisfies z.ZodType<ValidOrder>;
```

## Contract Generation from Types

```typescript
// Auto-generate contracts from Zod schema
type ContractFromSchema<T extends z.ZodType> = {
  readonly preconditions: ReadonlyArray<{
    readonly field: string;
    readonly constraint: string;
  }>;
};

function extractContracts<T>(schema: z.ZodType<T>): ContractFromSchema<typeof schema> {
  const preconditions: Array<{ field: string; constraint: string }> = [];

  if (schema instanceof z.ZodObject) {
    for (const [key, fieldSchema] of Object.entries(schema.shape)) {
      // Extract string constraints
      if (fieldSchema instanceof z.ZodString) {
        const checks = (fieldSchema as any)._def.checks || [];
        for (const check of checks) {
          if (check.kind === 'min' && check.value > 0) {
            preconditions.push({ field: key, constraint: 'non_empty' });
          }
          if (check.kind === 'email') {
            preconditions.push({ field: key, constraint: 'valid_email' });
          }
          if (check.kind === 'uuid') {
            preconditions.push({ field: key, constraint: 'valid_uuid' });
          }
        }
      }

      // Extract number constraints
      if (fieldSchema instanceof z.ZodNumber) {
        const checks = (fieldSchema as any)._def.checks || [];
        for (const check of checks) {
          if (check.kind === 'min') {
            preconditions.push({ field: key, constraint: `>= ${check.value}` });
          }
          if (check.kind === 'max') {
            preconditions.push({ field: key, constraint: `<= ${check.value}` });
          }
        }
      }
    }
  }

  return { preconditions };
}
```

## Verification Checklist

Before merging code with contracts:

- [ ] All preconditions checked at function entry
- [ ] All postconditions verified after execution
- [ ] Invariants checked after state mutations
- [ ] Property-based tests cover algebraic laws
- [ ] Edge cases tested (null, empty, boundary)
- [ ] Model-based tests for stateful code
- [ ] Refinement types for all domain values

## Pattern Quick Reference

| Need | Pattern |
|------|---------|
| Ensure input validity | Precondition + Refined Type |
| Ensure output correctness | Postcondition |
| Ensure state consistency | Invariant |
| Test many inputs | Property-based test |
| Test state machines | Model-based test |
| Encode constraints in types | Refinement types |
| Document contracts | Type signatures |
