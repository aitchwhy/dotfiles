import type { SkillDefinition } from '../schemas'
import { SkillName } from '../schemas'

export const optionPatternsSkill: SkillDefinition = {
  frontmatter: {
    name: SkillName('option-patterns'),
    description: 'Option<T> patterns to eliminate null virus. Explicit absence modeling.',
    allowedTools: ['Read', 'Write', 'Edit'],
    tokenBudget: 1200,
  },
  sections: [
    {
      heading: 'Overview',
      content: `# Option Patterns`,
    },
    {
      heading: 'The Null Virus',
      content: `\`\`\`typescript
const phone = user.phone ?? null;        // null spreads
const carrier = getCarrier(phone) ?? null; // spreads more
\`\`\``,
    },
    {
      heading: 'Option: Explicit Absence',
      content: `\`\`\`typescript
import { Option } from "effect";

// Convert at boundary
const phone: Option.Option<string> = Option.fromNullable(user.phoneNumber);

// Pattern match - compiler enforces both cases
const display = Option.match(phone, {
  onNone: () => "No phone",
  onSome: (p) => \`Phone: \${p}\`,
});

// Get with fallback
const phoneOrDefault = Option.getOrElse(phone, () => "N/A");

// For API responses (JSON needs null, not Option)
const apiPhone = Option.getOrNull(phone); // string | null
\`\`\``,
    },
    {
      heading: 'Schema Integration',
      content: `\`\`\`typescript
import { Schema } from "effect";

const User = Schema.Struct({
  id: Schema.String,
  // nullable API field -> Option in domain
  phone: Schema.OptionFromNullOr(Schema.String),
});

type User = typeof User.Type;
// { id: string; phone: Option<string> }
\`\`\``,
    },
    {
      heading: 'Domain Rules',
      content: `| Pattern | Status | Replacement |
|---------|--------|-------------|
| \`x ?? null\` | BANNED | \`Option.fromNullable(x)\` |
| \`T \\| null\` | BANNED | \`Option<T>\` |
| \`if (x === null)\` | BANNED | \`Option.match\` |
| \`x!\` | BANNED | Parse at boundary |`,
    },
    {
      heading: 'Boundaries',
      content: `\`\`\`typescript
// INPUT: nullable -> Option
const phone = Option.fromNullable(request.body.phone);

// OUTPUT: Option -> nullable for JSON
const response = { phone: Option.getOrNull(user.phone) };
\`\`\``,
    },
  ],
}
