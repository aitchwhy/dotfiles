---
name: tanstack-patterns
description: TanStack Router and Query patterns including file-based routing, data fetching, and optimistic updates. Use when working with React frontends.
allowed-tools: Read, Write
token-budget: 400
---

## File-Based Routing

### Route Directory Structure

```
src/routes/
├── __root.tsx        # Root layout
├── index.tsx         # / route
├── about.tsx         # /about route
├── users/
│   ├── index.tsx     # /users route
│   └── $userId.tsx   # /users/:userId route
└── _authenticated/   # Layout group (underscore prefix)
    ├── dashboard.tsx # /dashboard (requires auth)
    └── settings.tsx  # /settings (requires auth)
```

## Route Definition

### Route with Loader

```typescript
import { createFileRoute } from '@tanstack/react-router';

export const Route = createFileRoute('/users/$userId')({
  loader: async ({ params }) => {
    return fetchUser(params.userId);
  },
  component: UserPage,
});

function UserPage() {
  const user = Route.useLoaderData();
  return <div>{user.name}</div>;
}
```

## Query Patterns

### Optimistic Updates

```typescript
const mutation = useMutation({
  mutationFn: updateUser,
  onMutate: async (newData) => {
    await queryClient.cancelQueries({ queryKey: ['user', id] });
    const previous = queryClient.getQueryData(['user', id]);
    queryClient.setQueryData(['user', id], newData);
    return { previous };
  },
  onError: (err, newData, context) => {
    queryClient.setQueryData(['user', id], context?.previous);
  },
  onSettled: () => {
    queryClient.invalidateQueries({ queryKey: ['user', id] });
  },
});
```

## Search Params

### Validated Search Params

```typescript
import { z } from 'zod';

const searchSchema = z.object({
  page: z.number().default(1),
  sort: z.enum(['name', 'date']).default('name'),
});

export const Route = createFileRoute('/users')({
  validateSearch: searchSchema,
});

function UsersPage() {
  const { page, sort } = Route.useSearch();
}
```
