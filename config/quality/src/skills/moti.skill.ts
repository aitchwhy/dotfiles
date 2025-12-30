/**
 * Moti Skill
 *
 * Declarative animations for React Native.
 */

import type { SkillDefinition } from '../schemas'
import { SkillName } from '../schemas'

export const motiSkill: SkillDefinition = {
	frontmatter: {
		name: SkillName('moti'),
		description: 'Moti declarative animations for React Native',
		allowedTools: ['Read', 'Write', 'Edit', 'Grep'],
		tokenBudget: 400,
	},
	sections: [
		{
			heading: 'Why Moti',
			content: `
Moti provides declarative animations built on Reanimated:
- Works on iOS, Android, and Web
- Simpler API than raw Reanimated
- Automatic layout animations
- Presence animations (mount/unmount)

Use Moti for UI animations, Reanimated for gestures.
`,
		},
		{
			heading: 'Basic Animation',
			content: `
\`\`\`typescript
import { MotiView } from 'moti'

// Animate on mount
<MotiView
  from={{ opacity: 0, scale: 0.9 }}
  animate={{ opacity: 1, scale: 1 }}
  transition={{ type: 'timing', duration: 500 }}
>
  <Text>Fades and scales in</Text>
</MotiView>
\`\`\`
`,
		},
		{
			heading: 'State-Driven Animation',
			content: `
\`\`\`typescript
import { MotiView } from 'moti'

function Toggle({ isActive }: { isActive: boolean }) {
  return (
    <MotiView
      animate={{
        backgroundColor: isActive ? '#10B981' : '#6B7280',
        scale: isActive ? 1.1 : 1,
      }}
      transition={{ type: 'spring', damping: 15 }}
    />
  )
}
\`\`\`
`,
		},
		{
			heading: 'Presence (Enter/Exit)',
			content: `
\`\`\`typescript
import { AnimatePresence, MotiView } from 'moti'

function Modal({ visible }: { visible: boolean }) {
  return (
    <AnimatePresence>
      {visible && (
        <MotiView
          from={{ opacity: 0, translateY: 50 }}
          animate={{ opacity: 1, translateY: 0 }}
          exit={{ opacity: 0, translateY: 50 }}
          key="modal"
        />
      )}
    </AnimatePresence>
  )
}
\`\`\`
`,
		},
		{
			heading: 'Skeleton Loader',
			content: `
\`\`\`typescript
import { Skeleton } from 'moti/skeleton'

function LoadingCard() {
  return (
    <Skeleton.Group show={isLoading}>
      <Skeleton width={200} height={20} colorMode="light" />
      <Skeleton width={150} height={16} colorMode="light" />
    </Skeleton.Group>
  )
}
\`\`\`
`,
		},
		{
			heading: 'Transition Types',
			content: `
\`\`\`typescript
// Spring (bouncy, natural)
transition={{ type: 'spring', damping: 15, stiffness: 100 }}

// Timing (linear, predictable)
transition={{ type: 'timing', duration: 300 }}

// Decay (gesture-driven momentum)
transition={{ type: 'decay', velocity: 0.5 }}
\`\`\`

Prefer spring for UI, timing for opacity/color.
`,
		},
	],
}
