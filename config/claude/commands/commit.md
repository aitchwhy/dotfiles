Trunk-based development: commit, push, PR, rebase, and auto-merge.

## Context Detection

Determine current state:
- **Which repo?** Check `git remote -v` for repo context
- **Which branch?** If on `main`, create a worktree + feature branch first (see Step 1). If on a feature branch (e.g., `hank/told-1724`), skip to Step 2.
- **Worktree or main checkout?** If in a worktree, use that path for all operations. If on main, create one.

## Steps

### 1. Branch Setup (skip if already on feature branch)

If on `main` and there are uncommitted changes:

```bash
BRANCH="hank/<ticket-ref>"  # e.g., hank/told-1724
WORKTREE="$HOME/dotfiles-worktrees/<ticket-ref>"
mkdir -p "$HOME/dotfiles-worktrees"
git worktree add -b "$BRANCH" "$WORKTREE" main
```

Copy or move changed files to the worktree, then work from `$WORKTREE` for all remaining steps.

If no Linear ticket context exists, use a descriptive branch name: `hank/<scope>-<short-desc>`.

### 2. Stage and Commit

1. Run `git status` and `git diff` to understand all changes
2. Stage relevant files with `git add` (prefer specific files over `git add -A`)
3. Draft a conventional commit message: `type(scope): description`
   - Types: feat, fix, refactor, test, docs, chore, perf, ci
   - Lowercase first letter in description
   - Keep it concise (1 line)
4. Commit with the message

### 3. Rebase on Latest Main

```bash
git fetch origin main
git rebase origin/main
```

If conflicts arise, resolve them, `git add` the resolved files, and `git rebase --continue`.

### 4. Push and Create PR

```bash
git push -u origin HEAD
gh pr create --title "<commit message>" --body "$(cat <<'EOF'
## Summary
<1-3 bullet points>

Fixes <TICKET-ID>
EOF
)"
```

### 5. Wait for CI and Auto-Merge

```bash
# Wait for all PR checks to pass (timeout 5 minutes)
gh pr checks --watch --fail-fast
```

If checks pass:
```bash
gh pr merge --squash --delete-branch
```

If checks fail: report the failure and stop. Do NOT force merge.

### 6. Return to Main

```bash
# Clean up worktree if used
cd ~/dotfiles
git worktree remove "$WORKTREE" --force 2>/dev/null || true
git branch -D "$BRANCH" 2>/dev/null || true
git pull --ff-only
```

Report the merged PR URL.

---

If there are no changes to commit, say so and stop.
