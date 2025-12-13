---
name: refactoring-catalog
description: Fowler's refactoring patterns with mechanical transformation steps. Use when restructuring code without changing behavior.
allowed-tools: Read, Write, Edit, Grep, Glob
token-budget: 1700
---

## Refactoring Philosophy

Refactoring is behavior-preserving code transformation. **Tests must exist before refactoring begins.**

### Prerequisites

1. All tests pass before starting
2. Commit working state before each refactoring
3. Run tests after each transformation step
4. Commit after each successful refactoring

## Composing Methods

### Extract Function

**Trigger:** Code fragment that can be grouped together with semantic name.

```typescript
// BEFORE
function printOwing(invoice: Invoice) {
  console.log("***********************");
  console.log("**** Customer Owes ****");
  console.log("***********************");

  let outstanding = 0;
  for (const o of invoice.orders) {
    outstanding += o.amount;
  }
  console.log(`Amount: ${outstanding}`);
}

// AFTER
function printOwing(invoice: Invoice) {
  printBanner();
  const outstanding = calculateOutstanding(invoice);
  printDetails(outstanding);
}

function printBanner() {
  console.log("***********************");
  console.log("**** Customer Owes ****");
  console.log("***********************");
}

function calculateOutstanding(invoice: Invoice): number {
  return invoice.orders.reduce((sum, o) => sum + o.amount, 0);
}

function printDetails(outstanding: number) {
  console.log(`Amount: ${outstanding}`);
}
```

**Steps:**
1. Create new function with semantic name
2. Copy extracted code to new function
3. Identify variables needed (pass as parameters)
4. Identify variables modified (return them)
5. Replace original code with function call
6. Run tests

### Inline Function

**Trigger:** Function body is as clear as its name, or intermediary function is unhelpful.

```typescript
// BEFORE
function rating(driver: Driver): number {
  return moreThanFiveLateDeliveries(driver) ? 2 : 1;
}
function moreThanFiveLateDeliveries(driver: Driver): boolean {
  return driver.numberOfLateDeliveries > 5;
}

// AFTER
function rating(driver: Driver): number {
  return driver.numberOfLateDeliveries > 5 ? 2 : 1;
}
```

**Steps:**
1. Verify function is not polymorphic
2. Find all call sites
3. Replace each call with function body
4. Remove original function
5. Run tests

### Extract Variable

**Trigger:** Complex expression that needs explanation.

```typescript
// BEFORE
return order.quantity * order.itemPrice -
  Math.max(0, order.quantity - 500) * order.itemPrice * 0.05 +
  Math.min(order.quantity * order.itemPrice * 0.1, 100);

// AFTER
const basePrice = order.quantity * order.itemPrice;
const quantityDiscount = Math.max(0, order.quantity - 500) * order.itemPrice * 0.05;
const shipping = Math.min(basePrice * 0.1, 100);
return basePrice - quantityDiscount + shipping;
```

### Replace Temp with Query

**Trigger:** Temporary variable holds result of expression that could be a function.

```typescript
// BEFORE
const basePrice = quantity * itemPrice;
if (basePrice > 1000) return basePrice * 0.95;
return basePrice * 0.98;

// AFTER
get basePrice() { return this.quantity * this.itemPrice; }
// ...
if (this.basePrice > 1000) return this.basePrice * 0.95;
return this.basePrice * 0.98;
```

### Introduce Parameter Object

**Trigger:** Data items that regularly travel together.

```typescript
// BEFORE
function amountInvoiced(start: Date, end: Date) { ... }
function amountReceived(start: Date, end: Date) { ... }
function amountOverdue(start: Date, end: Date) { ... }

// AFTER
type DateRange = { readonly start: Date; readonly end: Date };
function amountInvoiced(range: DateRange) { ... }
function amountReceived(range: DateRange) { ... }
function amountOverdue(range: DateRange) { ... }
```

### Combine Functions into Class

**Trigger:** Functions operating on the same data.

```typescript
// BEFORE
function base(reading: Reading) { ... }
function taxableCharge(reading: Reading) { ... }
function calculateBaseCharge(reading: Reading) { ... }

// AFTER
class Reading {
  constructor(private readonly data: ReadingData) {}
  get base() { return this.data.baseRate * this.data.quantity; }
  get taxableCharge() { return Math.max(0, this.base - this.data.taxThreshold); }
  get calculateBaseCharge() { return this.base + this.taxableCharge; }
}
```

### Split Phase

**Trigger:** Code dealing with two different concerns.

```typescript
// BEFORE
function priceOrder(product: Product, quantity: number, shippingMethod: ShippingMethod) {
  const basePrice = product.basePrice * quantity;
  const discount = Math.max(quantity - product.discountThreshold, 0) * product.basePrice * product.discountRate;
  const shippingPerCase = (basePrice > shippingMethod.discountThreshold) ? shippingMethod.discountedFee : shippingMethod.feePerCase;
  const shippingCost = quantity * shippingPerCase;
  return basePrice - discount + shippingCost;
}

// AFTER
function priceOrder(product: Product, quantity: number, shippingMethod: ShippingMethod) {
  const priceData = calculatePricingData(product, quantity);
  return applyShipping(priceData, shippingMethod);
}

function calculatePricingData(product: Product, quantity: number): PriceData {
  const basePrice = product.basePrice * quantity;
  const discount = Math.max(quantity - product.discountThreshold, 0) * product.basePrice * product.discountRate;
  return { basePrice, quantity, discount };
}

function applyShipping(priceData: PriceData, shippingMethod: ShippingMethod): number {
  const shippingPerCase = (priceData.basePrice > shippingMethod.discountThreshold)
    ? shippingMethod.discountedFee
    : shippingMethod.feePerCase;
  return priceData.basePrice - priceData.discount + (priceData.quantity * shippingPerCase);
}
```

## Moving Features

### Move Function

**Trigger:** Function references elements in other contexts more than its own.

**Steps:**
1. Examine all program elements used by function
2. Check if function is polymorphic
3. Copy function to target context
4. Adjust to fit new context
5. Reference new function from source
6. Turn source into delegating function (or remove)
7. Run tests

### Move Field

**Trigger:** Field is used more by another class than the one it lives in.

**Steps:**
1. Ensure source field is encapsulated
2. Create field and accessors on target
3. Update references to use target
4. Remove source field
5. Run tests

### Replace Loop with Pipeline

**Trigger:** Loop that can be expressed as collection pipeline.

```typescript
// BEFORE
const names = [];
for (const person of people) {
  if (person.job === "engineer") {
    names.push(person.name);
  }
}

// AFTER
const names = people
  .filter(p => p.job === "engineer")
  .map(p => p.name);
```

### Remove Dead Code

**Trigger:** Code that is never executed.

**Steps:**
1. Verify code is truly unused (search for references)
2. Delete the code
3. Run tests
4. Commit

## Simplifying Conditional Logic

### Decompose Conditional

**Trigger:** Complex conditional with dense code in branches.

```typescript
// BEFORE
if (date < SUMMER_START || date > SUMMER_END) {
  charge = quantity * winterRate + winterServiceCharge;
} else {
  charge = quantity * summerRate;
}

// AFTER
if (isSummer(date)) {
  charge = summerCharge(quantity);
} else {
  charge = winterCharge(quantity);
}
```

### Consolidate Conditional Expression

**Trigger:** Multiple conditionals with same result.

```typescript
// BEFORE
if (employee.seniority < 2) return 0;
if (employee.monthsDisabled > 12) return 0;
if (employee.isPartTime) return 0;

// AFTER
if (isNotEligibleForDisability()) return 0;

function isNotEligibleForDisability(): boolean {
  return employee.seniority < 2
    || employee.monthsDisabled > 12
    || employee.isPartTime;
}
```

### Replace Nested Conditional with Guard Clauses

**Trigger:** Special cases obscured by nested conditionals.

```typescript
// BEFORE
function payAmount(employee: Employee): Money {
  let result: Money;
  if (employee.isSeparated) {
    result = { amount: 0, currency: 'USD' };
  } else {
    if (employee.isRetired) {
      result = retiredAmount();
    } else {
      result = normalPayAmount();
    }
  }
  return result;
}

// AFTER
function payAmount(employee: Employee): Money {
  if (employee.isSeparated) return { amount: 0, currency: 'USD' };
  if (employee.isRetired) return retiredAmount();
  return normalPayAmount();
}
```

### Replace Conditional with Polymorphism

**Trigger:** Conditional that switches on type.

```typescript
// BEFORE
function plumage(bird: Bird): string {
  switch (bird.type) {
    case 'EuropeanSwallow': return 'average';
    case 'AfricanSwallow': return bird.numberOfCoconuts > 2 ? 'tired' : 'average';
    case 'NorwegianBlueParrot': return bird.voltage > 100 ? 'scorched' : 'beautiful';
    default: return 'unknown';
  }
}

// AFTER
abstract class Bird {
  abstract plumage(): string;
}

class EuropeanSwallow extends Bird {
  plumage() { return 'average'; }
}

class AfricanSwallow extends Bird {
  plumage() { return this.numberOfCoconuts > 2 ? 'tired' : 'average'; }
}
```

### Introduce Special Case (Null Object)

**Trigger:** Many places check for special case value.

```typescript
// BEFORE
if (customer === null) return 'occupant';
return customer.name;

// AFTER
class UnknownCustomer {
  get name() { return 'occupant'; }
}
// ... customer is always an object, never null
return customer.name;
```

## Refactoring APIs

### Separate Query from Modifier

**Trigger:** Function both returns value and has side effect.

```typescript
// BEFORE
function getTotalOutstandingAndSendBill(): number {
  const result = customer.invoices.reduce((sum, inv) => sum + inv.amount, 0);
  sendBill();
  return result;
}

// AFTER
function totalOutstanding(): number {
  return customer.invoices.reduce((sum, inv) => sum + inv.amount, 0);
}
function sendBill(): void { /* ... */ }
```

### Remove Flag Argument

**Trigger:** Function behaves differently based on boolean flag.

```typescript
// BEFORE
function setDimension(name: string, value: number, isFinal: boolean) { ... }

// AFTER
function setDimension(name: string, value: number) { ... }
function setFinalDimension(name: string, value: number) { ... }
```

### Replace Parameter with Query

**Trigger:** Parameter value can be computed by function itself.

```typescript
// BEFORE
get finalPrice() {
  const basePrice = this.quantity * this.itemPrice;
  return this.discountedPrice(basePrice, this.discountLevel);
}
discountedPrice(basePrice: number, discountLevel: number) { ... }

// AFTER
get finalPrice() {
  return this.discountedPrice();
}
discountedPrice() {
  const basePrice = this.quantity * this.itemPrice;
  // uses this.discountLevel directly
}
```

### Replace Constructor with Factory Function

**Trigger:** Constructor has limitations (e.g., must return instance of class).

```typescript
// BEFORE
const engineer = new Employee('John', 'engineer');

// AFTER
const engineer = createEngineer('John');

function createEngineer(name: string): Employee {
  return new Employee(name, 'engineer');
}
```

## Verification Checklist

After any refactoring:

- [ ] All tests pass
- [ ] No behavior change (verified by tests)
- [ ] Code is more readable
- [ ] Duplication reduced (if applicable)
- [ ] Single Responsibility improved
- [ ] Committed with message: `refactor(scope): what was changed`
