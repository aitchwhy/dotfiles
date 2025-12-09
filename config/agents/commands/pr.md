---
description: Pull request creation helper
allowed-tools: Bash, Read, Grep
---

# Create Pull Request: $ARGUMENTS

## 1. Gather Context

```bash
git log main..HEAD --oneline
git diff main --stat
```

## 2. Generate PR Description

### Title

`type(scope): concise description`

### Description

**What**
- Summary of changes

**Why**
- Problem being solved
- Link to issue if applicable

**How**
- Implementation approach
- Key decisions made

**Testing**
- How was this tested?
- Any manual testing steps?

**Screenshots** (if UI changes)
- Before/After if applicable

## 3. Create PR

```bash
gh pr create --title "title" --body "description" $ARGUMENTS
```

## 4. Request Review

- Tag appropriate reviewers
- Add labels if applicable
