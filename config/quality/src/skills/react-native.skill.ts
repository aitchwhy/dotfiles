/**
 * React Native Skill
 *
 * Platform-specific patterns and safe practices.
 */

import type { SkillDefinition } from '../schemas'
import { SkillName } from '../schemas'

export const reactNativeSkill: SkillDefinition = {
	frontmatter: {
		name: SkillName('react-native'),
		description: 'React Native 0.79 platform patterns and safe practices',
		allowedTools: ['Read', 'Write', 'Edit', 'Grep'],
		tokenBudget: 500,
	},
	sections: [
		{
			heading: 'Platform-Specific Code',
			content: `
\`\`\`typescript
// Option 1: Platform.select
import { Platform } from 'react-native'

const styles = {
  padding: Platform.select({ ios: 20, android: 16, default: 16 }),
}

// Option 2: Platform-specific files
// Button.ios.tsx
// Button.android.tsx
// Button.tsx (fallback)
import Button from './Button'  // Auto-selects
\`\`\`
`,
		},
		{
			heading: 'Safe Area Handling',
			content: `
\`\`\`typescript
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context'

// Wrap entire screen
function Screen() {
  return (
    <SafeAreaView style={{ flex: 1 }}>
      <Content />
    </SafeAreaView>
  )
}

// Or use hooks for fine control
function Header() {
  const insets = useSafeAreaInsets()
  return <View style={{ paddingTop: insets.top }} />
}
\`\`\`
`,
		},
		{
			heading: 'Lists and Performance',
			content: `
\`\`\`typescript
// Use FlashList for large lists (Shopify)
import { FlashList } from '@shopify/flash-list'

<FlashList
  data={items}
  renderItem={({ item }) => <Item {...item} />}
  estimatedItemSize={80}  // Required for performance
  keyExtractor={(item) => item.id}
/>

// AVOID FlatList for 100+ items
\`\`\`
`,
		},
		{
			heading: 'Image Handling',
			content: `
\`\`\`typescript
// Use expo-image (NOT react-native Image)
import { Image } from 'expo-image'

<Image
  source={{ uri: 'https://example.com/image.jpg' }}
  style={{ width: 200, height: 200 }}
  contentFit="cover"
  placeholder={blurhash}
  transition={200}
/>
\`\`\`

expo-image provides caching, blurhash, and better performance.
`,
		},
		{
			heading: 'Keyboard Handling',
			content: `
\`\`\`typescript
import { KeyboardAvoidingView, Platform } from 'react-native'

<KeyboardAvoidingView
  behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
  style={{ flex: 1 }}
>
  <TextInput />
</KeyboardAvoidingView>
\`\`\`
`,
		},
	],
}
