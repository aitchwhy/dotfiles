---
name: verification-first
description: Verification-first development patterns. Ban assumption language. Replace "should work" with test evidence.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Verification-First Development (December 2025)

## Core Philosophy

**Every claim about code behavior must be backed by test evidence.**

The word "should" is banned when describing current behavior. You either:
1. **VERIFIED** via running test with output
2. **UNVERIFIED** with explicit acknowledgment

## Banned Language → Required Replacement

| ❌ BANNED | ✅ REQUIRED |
|-----------|-------------|
| "should now work" | "VERIFIED via test_user.py::test_login: assert response.status == 200 passed" |
| "should fix the bug" | "VERIFIED via user.test.ts:23: expect(result.ok).toBe(true) passed" |
| "this fixes" | "UNVERIFIED: claim requires test_payment_flow.py" |
| "will now have" | "VERIFIED via cargo test auth_module: 3/3 assertions passed" |
| "should be correct" | "VERIFIED via bun test --grep 'validation': all 5 tests passed" |
| "probably works" | "UNVERIFIED: needs integration test for edge case" |
| "likely fixed" | "VERIFIED via go test -v ./...: TestUserCreate PASS" |

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

### Failed Verification
```
❌ FAILED: [claim that was disproven]
   Test: [file_path]:[test_name]
   Expected: [what was expected]
   Actual: [what actually happened]
   Action: [next step to fix]
```

## Multi-Language Test Commands

### TypeScript/JavaScript (Bun)
```bash
# Run all tests
bun test

# Run specific pattern
bun test --grep "user authentication"

# Run single file
bun test tests/auth.test.ts

# Watch mode
bun test --watch
```

### Python (pytest)
```bash
# Run all tests
pytest

# Run with pattern
pytest -k "test_login"

# Run specific file
pytest tests/test_auth.py -v

# Run specific test
pytest tests/test_auth.py::test_login_success -v
```

### Go
```bash
# Run all tests
go test ./...

# Run specific pattern
go test -v -run "TestUser"

# Run specific package
go test -v ./internal/auth/...
```

### Rust
```bash
# Run all tests
cargo test

# Run specific pattern
cargo test user_auth

# Run with output
cargo test -- --nocapture
```

### Shell (Bats)
```bash
# Run bats tests
bats tests/*.bats

# Run specific file
bats tests/deploy.bats
```

## Hook Enforcement

This system is enforced by three hooks:

### 1. TDD Enforcer (PreToolUse)
- **Trigger**: Write/Edit/MultiEdit on source files
- **Action**: BLOCK if no corresponding test file exists
- **Languages**: TypeScript, JavaScript, Python, Go, Rust, Shell

### 2. Assumption Detector (Stop)
- **Trigger**: Session completion
- **Action**: BLOCK if high-severity assumption language detected
- **Patterns**: "should work", "should now", "this fixes", "will now"

### 3. Verification Gate (Stop)
- **Trigger**: Session completion
- **Action**: BLOCK if unverified claims exist in database
- **Table**: `verification_claims` with status tracking

## Red Flags

These phrases trigger immediate review:

| Pattern | Severity | Action |
|---------|----------|--------|
| "should now work" | 🔴 HIGH | BLOCK |
| "should work" | 🔴 HIGH | BLOCK |
| "this should fix" | 🔴 HIGH | BLOCK |
| "this will fix" | 🔴 HIGH | BLOCK |
| "will now have" | 🔴 HIGH | BLOCK |
| "this fixes" | 🔴 HIGH | BLOCK |
| "probably works" | 🟡 MEDIUM | WARN |
| "likely fixed" | 🟡 MEDIUM | WARN |
| "should be fine" | 🟡 MEDIUM | WARN |
| "I think it will" | 🟢 LOW | LOG |
| "assuming this" | 🟢 LOW | LOG |

## TDD Enforcement by Language

### TypeScript/JavaScript
```
Source: src/services/user.ts
Expected tests:
  - src/services/user.test.ts
  - src/services/user.spec.ts
  - src/services/__tests__/user.test.ts
  - tests/services/user.test.ts
```

### Python
```
Source: app/services/user.py
Expected tests:
  - app/services/test_user.py
  - app/services/user_test.py
  - tests/test_user.py
  - tests/services/test_user.py
```

### Go
```
Source: internal/user/user.go
Expected tests:
  - internal/user/user_test.go
```

### Rust
```
Source: src/user.rs
Expected tests:
  - src/user_test.rs
  - tests/user.rs
  - Inline: #[cfg(test)] module
```

## Verification Workflow

```
1. Make claim about code behavior
   ↓
2. Find or write test that verifies claim
   ↓
3. Run test and capture output
   ↓
4. Format as VERIFIED/UNVERIFIED/FAILED
   ↓
5. Include evidence in response
```

## Database Schema

Claims are tracked in SQLite:

```sql
-- Verification claims tracking
CREATE TABLE verification_claims (
    id INTEGER PRIMARY KEY,
    session_id TEXT NOT NULL,
    claim_text TEXT NOT NULL,
    claim_type TEXT CHECK(claim_type IN ('behavior', 'fix', 'feature', 'refactor')),
    verification_status TEXT CHECK(verification_status IN ('pending', 'verified', 'failed', 'skipped')),
    test_file TEXT,
    test_name TEXT,
    test_output TEXT,
    verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Example Session

```typescript
// ❌ BAD: Making assumptions
// "I've updated the login function. It should now work correctly."

// ✅ GOOD: Verification-first
// "I've updated the login function.
//
// ✅ VERIFIED: Login returns user data on valid credentials
//    Test: auth.test.ts:45 'valid login returns user'
//    Command: bun test --grep 'valid login'
//    Output: expect(result.data.email).toBe('test@example.com') ✓
//
// ✅ VERIFIED: Login rejects invalid password
//    Test: auth.test.ts:58 'invalid password returns error'
//    Command: bun test --grep 'invalid password'
//    Output: expect(result.error.code).toBe('INVALID_CREDENTIALS') ✓"
```
