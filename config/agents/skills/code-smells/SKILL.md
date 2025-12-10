---
name: code-smells
description: Robert C. Martin's Clean Code heuristics as detection rules. Use to identify code quality issues.
allowed-tools: Read, Grep, Glob
---

## Code Smell Detection

Code smells are indicators of deeper problems. Each smell below includes detection patterns and remediation.

## Comments (C1-C5)

### C1: Inappropriate Information

**Smell:** Comments contain info better held elsewhere (changelog, author, dates).

**Detection:**
```bash
rg "Author:|Date:|Revision:|@author|@date" --type ts
rg "TODO.*\d{4}-\d{2}-\d{2}" --type ts  # Dated TODOs
```

**Fix:** Remove; use git history for authorship/dates.

### C2: Obsolete Comment

**Smell:** Comment describes code that no longer exists or has changed.

**Detection:** Manual review - comment doesn't match adjacent code.

**Fix:** Update or delete the comment.

### C3: Redundant Comment

**Smell:** Comment says exactly what code says.

```typescript
// BAD
i++; // increment i

// WORSE
// This function returns the user
function getUser() { return user; }
```

**Fix:** Delete the comment.

### C4: Poorly Written Comment

**Smell:** Comment is unclear, uses poor grammar, is unnecessarily long.

**Fix:** Rewrite concisely or extract into well-named function.

### C5: Commented-Out Code

**Smell:** Code is commented rather than deleted.

**Detection:**
```bash
rg "//\s*(const|let|var|function|class|if|for|while|return)" --type ts
rg "/\*[\s\S]*?(const|let|function)[\s\S]*?\*/" --type ts
```

**Fix:** Delete it. Git preserves history.

## Environment (E1-E2)

### E1: Build Requires More Than One Step

**Smell:** Building requires multiple manual commands.

**Detection:** Check for multi-step build docs, missing `package.json` scripts.

**Fix:** Single command: `bun run build` or `just build`.

### E2: Tests Require More Than One Step

**Smell:** Running tests requires setup steps.

**Fix:** Single command: `bun test` or `just test`.

## Functions (F1-F4)

### F1: Too Many Arguments

**Smell:** Function has more than 3 parameters.

**Detection:**
```bash
ast-grep -p 'function $NAME($$$ARGS)' --lang ts | grep -E '\([^)]*,[^)]*,[^)]*,[^)]*\)'
```

**Fix:** Introduce Parameter Object.

```typescript
// BAD
function createUser(name: string, email: string, age: number, role: string, dept: string) {}

// GOOD
type CreateUserParams = {
  readonly name: string;
  readonly email: string;
  readonly age: number;
  readonly role: string;
  readonly department: string;
};
function createUser(params: CreateUserParams) {}
```

### F2: Output Arguments

**Smell:** Function modifies its arguments.

**Detection:**
```bash
rg "function.*\(.*\).*\{" -A 20 --type ts | grep -E "^\s+\w+\s*="  # Assignment to param
```

**Fix:** Return modified value instead.

```typescript
// BAD
function appendFooter(report: Report) {
  report.footer = "..."; // Mutates argument
}

// GOOD
function withFooter(report: Report): Report {
  return { ...report, footer: "..." };
}
```

### F3: Flag Arguments

**Smell:** Boolean parameter changes function behavior.

**Detection:**
```bash
rg "function \w+\([^)]*:\s*boolean" --type ts
rg "function \w+\([^)]*,\s*(true|false)\)" --type ts
```

**Fix:** Split into two functions.

```typescript
// BAD
function createFile(name: string, temp: boolean) {}

// GOOD
function createFile(name: string) {}
function createTempFile(name: string) {}
```

### F4: Dead Functions

**Smell:** Functions never called.

**Detection:**
```bash
# Find function definitions, then search for calls
rg "export function (\w+)" -o --type ts | while read fn; do
  count=$(rg "$fn\(" --type ts | wc -l)
  if [ "$count" -eq 1 ]; then echo "Possibly dead: $fn"; fi
done
```

**Fix:** Delete them.

## General Heuristics (G1-G36)

### G1: Multiple Languages in One File

**Smell:** File contains JS, HTML, CSS, SQL mixed together.

**Fix:** Separate concerns into different files.

### G2: Obvious Behavior Not Implemented

**Smell:** Function doesn't do what name suggests.

```typescript
// BAD: Name says "get", but might return null without indication
function getUser(id: string): User { ... }

// GOOD: Name indicates possibility of absence
function findUser(id: string): User | null { ... }
```

### G3: Incorrect Boundary Behavior

**Smell:** Code doesn't handle edge cases.

**Detection:** Check for missing null checks, empty array handling, boundary values.

**Fix:** Test and handle all boundaries.

### G4: Overridden Safeties

**Smell:** Disabling warnings, type assertions, `// @ts-ignore`.

**Detection:**
```bash
rg "@ts-ignore|@ts-expect-error|eslint-disable|as any|as unknown as" --type ts
```

**Fix:** Fix the underlying issue.

### G5: Duplication

**Smell:** Same code appears in multiple places (DRY violation).

**Detection:**
```bash
# Use jscpd or similar tool
npx jscpd src/
```

**Fix:** Extract to shared function/module.

### G6: Code at Wrong Level of Abstraction

**Smell:** High-level module knows low-level details.

```typescript
// BAD: Business logic knows about HTTP
function processOrder(order: Order) {
  fetch('/api/orders', { method: 'POST', body: JSON.stringify(order) });
}

// GOOD: Business logic uses abstraction
function processOrder(order: Order, orderService: OrderService) {
  orderService.submit(order);
}
```

### G9: Dead Code

**Smell:** Code that can never be executed.

**Detection:**
```bash
rg "if\s*\(\s*false\s*\)" --type ts
rg "return.*\n.*[^}]" --type ts  # Code after return
```

**Fix:** Delete it.

### G10: Vertical Separation

**Smell:** Related code is far apart vertically.

**Fix:** Local variables near first use; private functions near first caller.

### G11: Inconsistency

**Smell:** Similar things done differently.

```typescript
// BAD: Inconsistent naming
function fetchUser() {}
function getOrder() {}
function retrieveProduct() {}

// GOOD: Consistent
function getUser() {}
function getOrder() {}
function getProduct() {}
```

### G14: Feature Envy

**Smell:** Method uses more features from another class than its own.

**Detection:** Count method calls to `this` vs other objects.

**Fix:** Move method to the class it envies.

### G17: Misplaced Responsibility

**Smell:** Function is in wrong module.

**Fix:** Move to module where it logically belongs.

### G18: Inappropriate Static

**Smell:** Static method that should be instance method.

**Detection:** Static method that uses instance-like parameters.

**Fix:** Make it an instance method.

### G19: Use Explanatory Variables

**Smell:** Complex expression without intermediate variables.

```typescript
// BAD
if (platform.toUpperCase().indexOf("MAC") > -1 &&
    browser.toUpperCase().indexOf("IE") > -1 &&
    wasInitialized() && resize > 0) {}

// GOOD
const isMacOS = platform.toUpperCase().indexOf("MAC") > -1;
const isIE = browser.toUpperCase().indexOf("IE") > -1;
const wasResized = resize > 0;
if (isMacOS && isIE && wasInitialized() && wasResized) {}
```

### G20: Function Names Should Say What They Do

**Smell:** Name doesn't describe behavior.

```typescript
// BAD
function process(d: Date) {}

// GOOD
function addBusinessDays(date: Date, days: number): Date {}
```

### G23: Prefer Polymorphism to If/Else

**Smell:** Switch/if on type discriminator.

**Detection:**
```bash
rg "switch\s*\(\s*\w+\.type" --type ts
rg "if\s*\(\s*\w+\s*(===|==)\s*['\"]" --type ts
```

**Fix:** Use polymorphism or discriminated unions with exhaustive matching.

### G25: Replace Magic Numbers with Named Constants

**Smell:** Literal numbers in code.

**Detection:**
```bash
rg "\b\d{2,}\b" --type ts | grep -v "test"  # Numbers > 9
```

**Fix:**
```typescript
// BAD
if (age > 65) {}

// GOOD
const RETIREMENT_AGE = 65;
if (age > RETIREMENT_AGE) {}
```

### G28: Encapsulate Conditionals

**Smell:** Complex boolean expression inline.

```typescript
// BAD
if (timer.hasExpired() && !timer.isRecurrent()) {}

// GOOD
if (shouldBeDeleted(timer)) {}
function shouldBeDeleted(timer: Timer): boolean {
  return timer.hasExpired() && !timer.isRecurrent();
}
```

### G29: Avoid Negative Conditionals

**Smell:** Negated boolean in condition.

```typescript
// BAD
if (!buffer.shouldNotCompact()) {}

// GOOD
if (buffer.shouldCompact()) {}
```

### G30: Functions Should Do One Thing

**Smell:** Function has multiple responsibilities.

**Detection:** Function has multiple paragraphs or sections.

**Fix:** Extract each section into its own function.

### G31: Hidden Temporal Couplings

**Smell:** Functions must be called in specific order but order isn't enforced.

**Fix:** Make dependencies explicit via return values or builder pattern.

```typescript
// BAD
initialize();
process();  // Must be after initialize
cleanup();  // Must be after process

// GOOD
const initialized = initialize();
const processed = process(initialized);
cleanup(processed);
```

### G36: Avoid Transitive Navigation

**Smell:** `a.getB().getC().doSomething()` (Law of Demeter violation).

**Detection:**
```bash
rg "\.\w+\(\)\.\w+\(\)\.\w+\(" --type ts
```

**Fix:** Tell, don't ask. Add method to first object.

## Naming (N1-N7)

### N1: Choose Descriptive Names

**Smell:** Names like `d`, `temp`, `data`, `obj`.

**Detection:**
```bash
rg "\b(temp|tmp|data|obj|val|res|ret)\b\s*=" --type ts
```

### N3: Use Standard Nomenclature

**Smell:** Non-standard naming for patterns.

**Fix:** Use conventional names: `factory`, `visitor`, `strategy`, `observer`.

### N5: Use Long Names for Long Scopes

**Smell:** Short name used in large scope.

```typescript
// BAD (long scope)
const n = users.length;
// ... 50 lines later ...
for (let i = 0; i < n; i++) {}

// GOOD
const userCount = users.length;
```

### N7: Names Should Describe Side-Effects

**Smell:** Name doesn't indicate mutation or IO.

```typescript
// BAD
function getUser() {} // Actually fetches from network

// GOOD
function fetchUser() {}  // Indicates IO
function createUser() {} // Indicates creation
```

## Tests (T1-T9)

### T1: Insufficient Tests

**Smell:** Code paths not covered.

**Fix:** Aim for >80% coverage; test all edge cases.

### T3: Don't Skip Trivial Tests

**Smell:** Simple cases not tested because "obvious".

**Fix:** Test them anyway; they document behavior.

### T5: Test Boundary Conditions

**Smell:** Only happy path tested.

**Fix:** Test: null, empty, one, many, boundary values, overflow.

### T6: Exhaustively Test Near Bugs

**Smell:** Bug found but surrounding code not tested.

**Fix:** When bug found, add tests for related code.

### T9: Tests Should Be Fast

**Smell:** Test suite takes minutes.

**Fix:** Mock IO, parallelize, use in-memory databases.

## Quick Detection Commands

```bash
# Run all smell detections
echo "=== Commented code ===" && rg "//\s*(const|let|function)" --type ts
echo "=== Magic numbers ===" && rg "\b\d{3,}\b" --type ts | head -20
echo "=== ts-ignore ===" && rg "@ts-ignore|as any" --type ts
echo "=== Long functions ===" && ast-grep -p 'function $NAME($$$) { $$$BODY }' --lang ts
echo "=== Flag arguments ===" && rg ":\s*boolean" --type ts | head -20
echo "=== Chain calls ===" && rg "\.\w+\(\)\.\w+\(\)\.\w+\(" --type ts
```
