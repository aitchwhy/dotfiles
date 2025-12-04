---
description: Generate React component for Ember
allowed-tools: Write, Read
---

# Create Ember React Component: $ARGUMENTS

Generate a component following Ember patterns:

```tsx
import { type FC } from 'react';

interface ${ARGUMENTS}Props {
  // Define props with JSDoc comments
}

export const ${ARGUMENTS}: FC<${ARGUMENTS}Props> = (props) => {
  const { } = props;

  return (
    <div className="flex">
      {/* Component content */}
    </div>
  );
};
```

## Guidelines

- PascalCase component name
- Props interface with explicit types
- Tailwind for styling
- Extract hooks if > 10 lines of logic
- Colocate with page if page-specific
- Put in components/ if reusable

## File Location

- Page-specific: `apps/web/src/routes/{page}/components/{Name}.tsx`
- Shared: `apps/web/src/components/{Name}.tsx`
- UI primitives: `packages/ui/src/{Name}.tsx`
