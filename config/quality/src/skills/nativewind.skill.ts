/**
 * NativeWind Skill
 *
 * Tailwind CSS for React Native.
 */

import type { SkillDefinition } from '../schemas'
import { SkillName } from '../schemas'

export const nativewindSkill: SkillDefinition = {
	frontmatter: {
		name: SkillName('nativewind'),
		description: 'NativeWind (Tailwind for React Native) patterns',
		allowedTools: ['Read', 'Write', 'Edit', 'Grep'],
		tokenBudget: 400,
	},
	sections: [
		{
			heading: 'Setup',
			content: `
Required files:

\`\`\`javascript
// metro.config.js
const { withNativeWind } = require('nativewind/metro')
module.exports = withNativeWind(config, { input: './global.css' })
\`\`\`

\`\`\`css
/* global.css */
@tailwind base;
@tailwind components;
@tailwind utilities;
\`\`\`

\`\`\`typescript
// app/_layout.tsx
import '../global.css'
\`\`\`
`,
		},
		{
			heading: 'Basic Usage',
			content: `
\`\`\`typescript
import { View, Text } from 'react-native'

// Use className prop (NOT style)
<View className="flex-1 items-center justify-center bg-white">
  <Text className="text-2xl font-bold text-black">
    Hello NativeWind
  </Text>
</View>

// Conditional classes
<View className={\`p-4 \${isActive ? 'bg-blue-500' : 'bg-gray-200'}\`} />
\`\`\`
`,
		},
		{
			heading: 'Dark Mode',
			content: `
\`\`\`typescript
// Automatic with system preference
<View className="bg-white dark:bg-black">
  <Text className="text-black dark:text-white">
    Adapts to system theme
  </Text>
</View>

// app.json: userInterfaceStyle: "automatic"
\`\`\`
`,
		},
		{
			heading: 'Platform Variants',
			content: `
\`\`\`typescript
// iOS-only styles
<View className="ios:pt-12 android:pt-4" />

// Web-only styles
<View className="web:hover:bg-gray-100" />
\`\`\`
`,
		},
		{
			heading: 'Common Patterns',
			content: `
\`\`\`typescript
// Full screen centered
<View className="flex-1 items-center justify-center">

// Card with shadow
<View className="rounded-xl bg-white p-4 shadow-md">

// Row with gap
<View className="flex-row gap-2">

// Safe area padding (use hooks instead)
// AVOID: pt-safe - use useSafeAreaInsets()
\`\`\`
`,
		},
		{
			heading: 'Type Declarations',
			content: `
\`\`\`typescript
// nativewind-env.d.ts
/// <reference types="nativewind/types" />
\`\`\`

This enables className prop typing on all RN components.
`,
		},
	],
}
