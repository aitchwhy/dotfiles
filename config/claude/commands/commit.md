Git add, commit, push, and auto-merge in one step (trunk-based development).

1. Run `git status` and `git diff` to understand all changes
2. Stage the relevant changed files with `git add` (prefer specific files over `git add -A`)
3. Draft a conventional commit message: `type(scope): description`
   - Types: feat, fix, refactor, test, docs, chore, perf, ci
   - Lowercase first letter in description
   - Keep it concise (1 line)
4. If on `main`, create a short-lived feature branch: `git checkout -b hank/<scope>-<short-desc>`
5. Commit with the message
6. Push to remote with `-u`
7. Create PR with `gh pr create --title "<commit message>" --body "Auto-merge commit."`
8. Squash merge immediately: `gh pr merge --squash --delete-branch`
9. Return to main and pull: `git checkout main && git pull --ff-only`

If there are no changes to commit, say so and stop.
