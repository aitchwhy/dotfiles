---
name: verification-first
description: Verification-first development patterns. Ban assumption language. Replace "should work" with test evidence.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

## Core Philosophy

**Every claim about code behavior must be backed by test evidence.**

The word "should" is banned when describing current behavior. You either:
1. **VERIFIED** via running test with output
2. **UNVERIFIED** with explicit acknowledgment

## Banned Language → Required Replacement

| ❌ BANNED | ✅ REQUIRED |
|-----------|-------------|
| "should now work" | "VERIFIED via test: assertion passed" |
| "should fix the bug" | "VERIFIED via test: specific output" |
| "this fixes" | "UNVERIFIED: requires test_name" |
| "will now have" | "VERIFIED via test: assertion" |
| "probably works" | "UNVERIFIED: needs specific test" |

## Verification Evidence Format

### Verified Claims

```
✅ VERIFIED: [specific claim about behavior]
   Test: [file_path]:[test_name or line_number]
   Command: [exact command run]
   Output: [relevant assertion or test output]
```

### Unverified Claims

```
⚠️ UNVERIFIED: [specific claim about behavior]
   Reason: [why verification wasn't done]
   Needed: [specific test that would verify this]
   Risk: [impact if claim is wrong]
```

## Multi-Language Test Commands

### Test Runners by Language

```bash
# TypeScript/JavaScript (Bun)
bun test --grep "pattern"

# Python (pytest)
pytest -k "test_login" -v

# Go
go test -v -run "TestUser"

# Rust
cargo test user_auth
```

## Red Flags

| Pattern | Severity | Action |
|---------|----------|--------|
| "should now work" | 🔴 HIGH | BLOCK |
| "this should fix" | 🔴 HIGH | BLOCK |
| "probably works" | 🟡 MEDIUM | WARN |
| "likely fixed" | 🟡 MEDIUM | WARN |
