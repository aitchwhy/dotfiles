/**
 * Expo Skill
 *
 * Expo SDK 53 / Router v5 patterns.
 */

import type { SkillDefinition } from '../schemas'
import { SkillName } from '../schemas'

export const expoSkill: SkillDefinition = {
	frontmatter: {
		name: SkillName('expo'),
		description: 'Expo SDK 53 / Router v5 patterns and commands',
		allowedTools: ['Read', 'Write', 'Edit', 'Bash', 'Grep'],
		tokenBudget: 500,
	},
	sections: [
		{
			heading: 'Project Structure',
			content: `
\`\`\`
apps/mobile/
├── app/           # File-based routing (Expo Router)
│   ├── _layout.tsx
│   ├── index.tsx
│   └── (tabs)/
├── assets/
├── app.json       # Expo config
├── metro.config.js
└── package.json
\`\`\`
`,
		},
		{
			heading: 'Common Commands',
			content: `
\`\`\`bash
# Development
pnpm --filter @scope/mobile start     # Start Metro
pnpm --filter @scope/mobile ios       # iOS simulator
pnpm --filter @scope/mobile android   # Android emulator
pnpm --filter @scope/mobile web       # Web browser

# From apps/mobile
npx expo start
npx expo run:ios
npx expo run:android
\`\`\`
`,
		},
		{
			heading: 'Expo Router Navigation',
			content: `
\`\`\`typescript
// File-based routing
// app/index.tsx -> /
// app/profile.tsx -> /profile
// app/(tabs)/home.tsx -> /home (grouped)

import { Link, useRouter } from 'expo-router'

// Declarative navigation
<Link href="/profile">Go to Profile</Link>

// Imperative navigation
const router = useRouter()
router.push('/profile')
router.replace('/home')
router.back()
\`\`\`
`,
		},
		{
			heading: 'Layout Files',
			content: `
\`\`\`typescript
// app/_layout.tsx - Root layout
import { Stack } from 'expo-router'

export default function RootLayout() {
  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="index" />
      <Stack.Screen name="(tabs)" />
    </Stack>
  )
}
\`\`\`
`,
		},
		{
			heading: 'New Architecture (SDK 53)',
			content: `
SDK 53 defaults to New Architecture:
- \`newArchEnabled: true\` in app.json
- TurboModules for native modules
- Fabric renderer for UI
- Concurrent features enabled

If issues arise, disable temporarily:
\`\`\`json
{ "expo": { "newArchEnabled": false } }
\`\`\`
`,
		},
	],
}
