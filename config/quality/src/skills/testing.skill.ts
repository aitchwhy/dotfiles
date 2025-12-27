/**
 * Testing Skill
 *
 * TDD with Layer substitution, no mocks.
 */

import type { SkillDefinition } from '../schemas'
import { SkillName } from '../schemas'

export const testingSkill: SkillDefinition = {
  frontmatter: {
    name: SkillName('testing'),
    description: 'TDD with Effect Layer substitution, no mocking frameworks',
    allowedTools: ['Read', 'Write', 'Edit', 'Grep', 'Bash'],
    tokenBudget: 400,
  },
  sections: [
    {
      heading: 'TDD with Effect',
      content: `
Red-Green-Refactor with typed effects:

1. **Red**: Write failing test with expected behavior
2. **Green**: Implement minimal code to pass
3. **Refactor**: Improve while tests stay green

\`\`\`typescript
describe("createOrder", () => {
  it("fails if product not found", async () => {
    const result = await Effect.runPromiseExit(
      createOrder({ productId: "missing" }).pipe(
        Effect.provide(TestLayers)
      )
    );
    expect(Exit.isFailure(result)).toBe(true);
  });
});
\`\`\`
`,
    },
    {
      heading: 'Test Layers',
      content: `
\`\`\`typescript
// Create test implementations
const ProductRepoTest = Layer.succeed(ProductRepository, {
  findById: () => Effect.succeed(testProduct),
  save: () => Effect.succeed(undefined),
});

const OrderRepoTest = Layer.succeed(OrderRepository, {
  create: (order) => Effect.succeed({ ...order, id: "test-id" }),
});

// Combine for tests
const TestLayers = Layer.mergeAll(
  ProductRepoTest,
  OrderRepoTest,
  ClockTest,
);
\`\`\`
`,
    },
    {
      heading: 'Testing Error Paths',
      content: `
\`\`\`typescript
it("handles payment failure", async () => {
  const FailingPayment = Layer.succeed(PaymentService, {
    charge: () => Effect.fail(new PaymentDeclinedError({ reason: "test" })),
  });

  const result = await Effect.runPromiseExit(
    processOrder(testOrder).pipe(
      Effect.provide(FailingPayment),
      Effect.provide(OtherTestLayers)
    )
  );

  expect(Exit.isFailure(result)).toBe(true);
});
\`\`\`
`,
    },
    {
      heading: 'Anti-Patterns',
      content: `
- **jest.mock()** → Use Layer substitution
- **vi.fn()** → Use real test implementations
- **Partial mocks** → Full test adapters
- **Testing implementation** → Test behavior via public API
`,
    },
  ],
}
