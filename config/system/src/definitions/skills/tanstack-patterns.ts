/**
 * TanStack Patterns Skill Definition
 *
 * TanStack Router and Query patterns for React frontends.
 * Migrated from: config/claude-code/skills/tanstack-patterns/SKILL.md
 */
import type { SystemSkill } from '@/schema'

export const tanstackPatternsSkill: SystemSkill = {
  name: 'tanstack-patterns' as SystemSkill['name'],
  description:
    'TanStack Router and Query patterns including file-based routing, data fetching, and optimistic updates. Use when working with React frontends.',
  allowedTools: ['Read', 'Write'] as SystemSkill['allowedTools'],

  sections: [
    {
      title: 'File-Based Routing',
      patterns: [
        {
          title: 'Route Directory Structure',
          annotation: 'info',
          language: 'text',
          code: `src/routes/
├── __root.tsx        # Root layout
├── index.tsx         # / route
├── about.tsx         # /about route
├── users/
│   ├── index.tsx     # /users route
│   └── $userId.tsx   # /users/:userId route
└── _authenticated/   # Layout group (underscore prefix)
    ├── dashboard.tsx # /dashboard (requires auth)
    └── settings.tsx  # /settings (requires auth)`,
        },
      ],
    },
    {
      title: 'Route Definition',
      patterns: [
        {
          title: 'Route with Loader',
          annotation: 'do',
          language: 'typescript',
          code: `import { createFileRoute } from '@tanstack/react-router';

export const Route = createFileRoute('/users/$userId')({
  loader: async ({ params }) => {
    return fetchUser(params.userId);
  },
  component: UserPage,
});

function UserPage() {
  const user = Route.useLoaderData();
  return <div>{user.name}</div>;
}`,
        },
      ],
    },
    {
      title: 'Query Patterns',
      patterns: [
        {
          title: 'Optimistic Updates',
          annotation: 'do',
          language: 'typescript',
          code: `const mutation = useMutation({
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
});`,
        },
      ],
    },
    {
      title: 'Search Params',
      patterns: [
        {
          title: 'Validated Search Params',
          annotation: 'do',
          language: 'typescript',
          code: `import { z } from 'zod';

const searchSchema = z.object({
  page: z.number().default(1),
  sort: z.enum(['name', 'date']).default('name'),
});

export const Route = createFileRoute('/users')({
  validateSearch: searchSchema,
});

function UsersPage() {
  const { page, sort } = Route.useSearch();
}`,
        },
      ],
    },
  ],
}
