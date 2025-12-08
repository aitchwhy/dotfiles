/**
 * Verification First Skill Definition
 *
 * Ban assumption language. Replace "should work" with test evidence.
 * Migrated from: config/claude-code/skills/verification-first/SKILL.md
 */
import type { SystemSkill } from '@/schema'

export const verificationFirstSkill: SystemSkill = {
  name: 'verification-first' as SystemSkill['name'],
  description:
    'Verification-first development patterns. Ban assumption language. Replace "should work" with test evidence.',
  allowedTools: ['Read', 'Write', 'Edit', 'Bash', 'Grep', 'Glob'] as SystemSkill['allowedTools'],

  sections: [
    {
      title: 'Core Philosophy',
      content: `**Every claim about code behavior must be backed by test evidence.**

The word "should" is banned when describing current behavior. You either:
1. **VERIFIED** via running test with output
2. **UNVERIFIED** with explicit acknowledgment`,
    },
    {
      title: 'Banned Language → Required Replacement',
      content: `| ❌ BANNED | ✅ REQUIRED |
|-----------|-------------|
| "should now work" | "VERIFIED via test: assertion passed" |
| "should fix the bug" | "VERIFIED via test: specific output" |
| "this fixes" | "UNVERIFIED: requires test_name" |
| "will now have" | "VERIFIED via test: assertion" |
| "probably works" | "UNVERIFIED: needs specific test" |`,
    },
    {
      title: 'Verification Evidence Format',
      patterns: [
        {
          title: 'Verified Claims',
          annotation: 'do',
          language: 'text',
          code: `✅ VERIFIED: [specific claim about behavior]
   Test: [file_path]:[test_name or line_number]
   Command: [exact command run]
   Output: [relevant assertion or test output]`,
        },
        {
          title: 'Unverified Claims',
          annotation: 'info',
          language: 'text',
          code: `⚠️ UNVERIFIED: [specific claim about behavior]
   Reason: [why verification wasn't done]
   Needed: [specific test that would verify this]
   Risk: [impact if claim is wrong]`,
        },
      ],
    },
    {
      title: 'Multi-Language Test Commands',
      patterns: [
        {
          title: 'Test Runners by Language',
          annotation: 'info',
          language: 'bash',
          code: `# TypeScript/JavaScript (Bun)
bun test --grep "pattern"

# Python (pytest)
pytest -k "test_login" -v

# Go
go test -v -run "TestUser"

# Rust
cargo test user_auth`,
        },
      ],
    },
    {
      title: 'Red Flags',
      content: `| Pattern | Severity | Action |
|---------|----------|--------|
| "should now work" | 🔴 HIGH | BLOCK |
| "this should fix" | 🔴 HIGH | BLOCK |
| "probably works" | 🟡 MEDIUM | WARN |
| "likely fixed" | 🟡 MEDIUM | WARN |`,
    },
  ],
}
