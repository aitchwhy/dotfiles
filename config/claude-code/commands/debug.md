---
description: Hypothesis-driven debugging
allowed-tools: Read, Bash, Grep, Glob
---

# Debug: $ARGUMENTS

## 1. Reproduce

- Confirm the issue exists
- Document exact steps to reproduce
- Note any error messages verbatim

## 2. Hypothesize

Generate 3 hypotheses ranked by likelihood:

1. [Most likely] ...
2. [Possible] ...
3. [Less likely] ...

## 3. Investigate

For each hypothesis:
- What evidence would confirm/deny it?
- What code/logs should I check?
- Execute investigation steps

## 4. Root Cause

- State the confirmed root cause
- Explain WHY it happens, not just what

## 5. Fix

- Propose the minimal fix
- Explain why this fix addresses root cause
- Implement the fix

## 6. Prevent

- How can we prevent this class of bug?
- Should we add a test?
- Should we add validation?
