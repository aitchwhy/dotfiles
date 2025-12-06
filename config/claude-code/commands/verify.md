---
description: Verify a claim with test evidence
allowed-tools: Read, Bash, Grep, Glob
---

# Verify Claim: $ARGUMENTS

## Purpose

Replace assumption language ("should work") with test evidence.

## Process

1. **Parse the claim** from arguments
2. **Find relevant test** using pattern matching:
   - Search for test file covering this functionality
   - Identify specific test case(s) that verify the claim
3. **Run the test** and capture output
4. **Format verification evidence**

## Output Format

### If VERIFIED:
```
✅ VERIFIED: [claim]
   Test: [test_file]:[test_name]
   Output: [relevant assertion output]
   Command: [test command used]
```

### If UNVERIFIED:
```
⚠️ UNVERIFIED: [claim]
   Reason: [why it can't be verified]
   Needed: [specific test that should be written]
```

### If FAILED:
```
❌ FAILED: [claim]
   Test: [test_file]:[test_name]
   Error: [failure message]
   Action: Fix the code or update the claim
```

## Test Discovery

Search patterns by language:
- **TypeScript/JS**: `*.test.ts`, `*.spec.ts`, `__tests__/*.ts`
- **Python**: `test_*.py`, `*_test.py`, `tests/test_*.py`
- **Go**: `*_test.go`
- **Rust**: `*_test.rs`, `tests/*.rs`
- **Shell**: `*.bats`, `*_test.sh`

## Commands

```bash
# TypeScript/JavaScript
bun test --grep "[pattern]"

# Python
pytest -k "[pattern]" -v

# Go
go test -v -run "[pattern]"

# Rust
cargo test "[pattern]" -- --nocapture
```

## Guidelines

- Never say "should work" - either verify or mark UNVERIFIED
- One verification per claim
- Include actual test output, not summaries
- If no test exists, recommend writing one
