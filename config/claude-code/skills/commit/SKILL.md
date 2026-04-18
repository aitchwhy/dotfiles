---
name: commit
allowed-tools: Bash(git *), Bash(gh *), Bash(eval *), Bash(export *), Bash(jq *), Bash(curl *), Bash(while *), Bash(sleep *), Bash(date *), Bash(ls *), Bash(rm *), Read, Edit, Glob, Grep, Task
description: Commit, push, create PR, monitor checks, auto-merge, and clean up worktree
disable-model-invocation: true
---

# Commit -> PR -> Merge -> Clean Up

Full ship-it workflow for the vault repo. Commit, push PR, monitor to merge, clean up worktree.

**CRITICAL: This command does NOT end until ALL phases complete. You MUST execute every phase sequentially — do not stop after PR creation, do not skip cleanup. If you have not printed `WORKFLOW COMPLETE` at the end, you are NOT done.**

## Phase 1: Commit

1. `git status` — review what's changed (never use `-uall`)
2. `git diff --stat` — summarize the diff
3. `git log --oneline -5` — match existing commit message style
4. Stage relevant files by name (avoid `git add -A` unless everything should go in)
5. Skip files that look like secrets (`.env`, credentials, tarballs, etc.)
6. Commit with a conventional commit message:
   - Subject must be lowercase, single-line
   - Types: feat, fix, refactor, docs, chore

**Print: `✓ Phase 1 (Commit) complete. → Phase 2: Push`**

## Phase 2: Push + Extract Ticket IDs

### Push

1. If on `main`, create a feature branch first: `git checkout -b <type>/<short-description>`
2. `git push -u origin HEAD`

### Extract ticket numbers from branch name

```bash
branch=$(git branch --show-current)
# Extract all {team}-{N} matches from the branch name (e.g., told-1794)
ticket_refs=$(echo "$branch" | grep -oE '[a-z]+-[0-9]+')
```

Store these as `ticket_refs` (lowercase like `told-1794`) and `ticket_ids` (uppercase like `TOLD-1794`).

**Print: `✓ Phase 2 (Push) complete. Tickets: {ticket_ids}. → Phase 3: Create PR`**

## Phase 3: Create PR

The PR body **MUST** include `Fixes {TEAM}-{N}` for each ticket — this triggers Linear's "Done" transition on merge.

```
gh pr create --title "<conventional commit title> [{TEAM}-{N}]" --body "$(cat <<'EOF'
## Summary
<1-3 bullet points>

## Test plan
- [ ] Open in Obsidian — frontmatter parsed, markdown renders correctly
<other manual checks as applicable>

---
Fixes {TEAM}-{N}
EOF
)"
```

**Print: `✓ Phase 3 (PR created). DO NOT STOP. → Phase 4: Monitor + Merge`**

---

**⚠️ CRITICAL CHECKPOINT: You are NOT done. The PR exists but is not merged. Phases 4-5 are MANDATORY. Proceed immediately.**

---

## Phase 4: Auto-merge + Monitor

**Do not skip this phase. Stay here until the PR is MERGED.**

1. Enable auto-merge: `gh pr merge <number> --auto --squash`
   - Try `--squash` first, fall back to `--rebase`, then `--merge`
   - If GitHub API returns 502/errors, retry with `sleep 10` up to 5 times
2. Watch for merge:
   ```bash
   while true; do
     pr_state=$(gh pr view <number> --json state --jq '.state')
     echo "$(date +%H:%M:%S) PR state: $pr_state"
     if [ "$pr_state" = "MERGED" ]; then break; fi
     if [ "$pr_state" = "CLOSED" ]; then echo "PR was closed without merging!"; break; fi
     sleep 10
   done
   ```
3. If auto-merge doesn't trigger after 60s, merge manually:
   `gh pr merge <number> --squash --delete-branch`

**Print: `✓ Phase 4 (Merged). → Phase 5: Clean up`**

## Phase 5: Clean Up Worktree + Verify Tickets

**MANDATORY — do not skip this phase.**

### Detect worktree

Determine if you're in a worktree:
```bash
worktree_dir=$(git rev-parse --show-toplevel)
main_repo="$HOME/src/told-vault"
```

### If in a worktree (worktree_dir != main_repo):

1. Note the worktree path and branch name before leaving
2. Switch to the main repo:
   ```bash
   cd "$main_repo"
   ```
3. Pull merged changes into main:
   ```bash
   git fetch --prune
   git pull --ff-only
   ```
4. Remove the worktree:
   ```bash
   git worktree remove "<worktree_dir>" --force
   ```
5. Delete the local branch:
   ```bash
   git branch -D "<branch_name>"
   ```
6. Prune stale worktree refs:
   ```bash
   git worktree prune
   ```
7. Remove parent worktree directory if empty:
   ```bash
   rmdir "$HOME/told-worktrees" 2>/dev/null || true
   ```

### If on main repo (not a worktree):

1. `git fetch --prune`
2. `git pull --ff-only`
3. Delete merged local branch: `git branch -D <feature-branch>`

### Verify clean state

```bash
git log --oneline -3  # should show merged commit
git status            # should be clean
git worktree list     # should only show main repo
```

### Verify Linear tickets are "Done" (safety net)

For each ticket referenced in the PR:

```bash
export LINEAR_API_TOKEN="${LINEAR_API_TOKEN:-$(esc open told/app/local-web --format json 2>/dev/null | jq -r '.environmentVariables.LINEAR_API_TOKEN // empty')}"
if [ -n "${LINEAR_API_TOKEN:-}" ]; then
  TEAM_KEY="${TICKET_ID%%-*}"

  STATE_ID=$(jq -n --arg team "$TEAM_KEY" --arg state "Done" \
    '{"query": "query($team: String!, $state: String!) { workflowStates(filter: { team: { key: { eq: $team } }, name: { eq: $state } }) { nodes { id name } } }", "variables": {"team": $team, "state": $state}}' \
    | curl -s -X POST "https://api.linear.app/graphql" \
      -H "Authorization: $LINEAR_API_TOKEN" -H "Content-Type: application/json" -d @- \
    | jq -r '.data.workflowStates.nodes[0].id // empty')

  if [ -n "$STATE_ID" ]; then
    jq -n --arg id "$TICKET_ID" --arg stateId "$STATE_ID" \
      '{"query": "mutation($id: String!, $stateId: String!) { issueUpdate(id: $id, input: { stateId: $stateId }) { success } }", "variables": {"id": $id, "stateId": $stateId}}' \
      | curl -s -X POST "https://api.linear.app/graphql" \
        -H "Authorization: $LINEAR_API_TOKEN" -H "Content-Type: application/json" -d @-
  fi
fi
```

> **Best-effort transitions:** If the call fails, log and continue. The PR body's `Fixes {TEAM}-xxx` handles it on merge.

**Print: `✓ Phase 5 (Cleanup) complete. WORKFLOW COMPLETE.`**

## Completion

**ONLY print this section after ALL phases have executed.**

Print:
```
WORKFLOW COMPLETE: {PR URL} merged and cleaned up.

Ticket status:
- {TEAM}-{N}: Done ✓
```
