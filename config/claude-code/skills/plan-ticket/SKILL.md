---
name: plan-ticket
allowed-tools: Task, Read, Edit, Bash, Glob, Grep
argument-hint: "<ticket-id(s) e.g. TOLD-299, '299 300', or TOLD-33,35>"
description: "Plan implementation for Linear tickets. Architect → locked plan → implementation."
disable-model-invocation: true
model: opus
---

# Plan-Ticket: Simplified Planning Pipeline

**CRITICAL: Follow ALL 3 phases sequentially. Do not skip phases. Do not stop early. This skill plans AND begins implementation — it does NOT stop after planning.**

## Phase 1: Setup

Parse `$ARGUMENTS` to extract ticket ID(s). Arguments may contain multiple IDs separated by spaces or commas.

For **each** token in the arguments, apply these rules:

1. If **empty**: respond with "Usage: `/plan-ticket <ticket-id>` (e.g., `TOLD-299`, `299`, or `299 300`)" → **STOP**
2. If contains `linear.app`: extract `{TEAM}-{N}` from the URL path
3. If matches `{letters}-{digits}` (e.g., `TOLD-299`, `told-299`): uppercase the team prefix → `TOLD-299`
4. If **numeric only** (e.g., `299`): prepend `TOLD-` → `TOLD-299` (default team)
5. If a comma-separated list has a leading prefixed ID (e.g., `TOLD-33,35`): infer the team prefix for bare numbers from the first prefixed ID → `TOLD-33`, `TOLD-35`
6. Store arrays for the rest of the pipeline:
   - `ticket_ids` — e.g., `["TOLD-299", "TOLD-300"]`
   - `ticket_refs` — lowercase refs e.g., `["told-299", "told-300"]`
   - `primary_ticket_id` — first ticket ID (used for plan file naming and architect focus)
   - `primary_ticket_ref` — first ticket ref in lowercase (used for plan file and branch naming)

### Create feature worktree

Create an isolated worktree so parallel `/plan-ticket` sessions don't collide on `main`.

```bash
BRANCH="hank/{primary_ticket_ref}"
WORKTREE="$HOME/told-vault-worktrees/{primary_ticket_ref}"
mkdir -p "$HOME/told-vault-worktrees"

# Clean stale worktree from previous failed run
if [ -d "$WORKTREE" ]; then
  git worktree remove "$WORKTREE" --force 2>/dev/null || rm -rf "$WORKTREE"
fi

# Create worktree on feature branch from main
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  git worktree add "$WORKTREE" "$BRANCH"
else
  git worktree add -b "$BRANCH" "$WORKTREE" main
fi

echo "Worktree: $WORKTREE"
echo "Branch: $BRANCH"
```

Store `WORKTREE_PATH = $HOME/told-vault-worktrees/{primary_ticket_ref}` for Phase 3.

**CRITICAL**: Phase 3 implementation MUST use `WORKTREE_PATH` for ALL file paths. For example, use `$WORKTREE_PATH/decisions/PITCH.md` — NOT the main repo path. The main repo stays untouched.

Create the plans directory:
```bash
mkdir -p ~/.claude/plans
```

### Source LINEAR_API_TOKEN

Claude Code's Bash tool does not persist environment variables between calls. Source inline in every Bash call that needs it:

```bash
# Source LINEAR_API_TOKEN from ESC (required: each Bash call is a fresh shell)
export LINEAR_API_TOKEN="${LINEAR_API_TOKEN:-$(esc open told/app/local-web --format json 2>/dev/null | jq -r '.environmentVariables.LINEAR_API_TOKEN // empty')}"
if [ -z "${LINEAR_API_TOKEN:-}" ]; then
  echo "Warning: LINEAR_API_TOKEN not available. Linear API calls will be skipped."
fi
```

**IMPORTANT**: Every subsequent Bash call that needs LINEAR_API_TOKEN must inline-source it using the same pattern above.

### Transition tickets to "In Progress"

For EACH ticket_id, transition to "In Progress" in Linear via GraphQL API. Planning means work has started.

```bash
# Source LINEAR_API_TOKEN from ESC (required: each Bash call is a fresh shell)
export LINEAR_API_TOKEN="${LINEAR_API_TOKEN:-$(esc open told/app/local-web --format json 2>/dev/null | jq -r '.environmentVariables.LINEAR_API_TOKEN // empty')}"
if [ -n "${LINEAR_API_TOKEN:-}" ]; then
  TEAM_KEY="${TICKET_ID%%-*}"

  # Resolve human-readable state name to UUID
  STATE_ID=$(jq -n --arg team "$TEAM_KEY" --arg state "In Progress" \
    '{"query": "query($team: String!, $state: String!) { workflowStates(filter: { team: { key: { eq: $team } }, name: { eq: $state } }) { nodes { id name } } }", "variables": {"team": $team, "state": $state}}' \
    | curl -s -X POST "https://api.linear.app/graphql" \
      -H "Authorization: $LINEAR_API_TOKEN" -H "Content-Type: application/json" -d @- \
    | jq -r '.data.workflowStates.nodes[0].id // empty')

  if [ -n "$STATE_ID" ]; then
    jq -n --arg id "$TICKET_ID" --arg stateId "$STATE_ID" \
      '{"query": "mutation($id: String!, $stateId: String!) { issueUpdate(id: $id, input: { stateId: $stateId }) { success } }", "variables": {"id": $id, "stateId": $stateId}}' \
      | curl -s -X POST "https://api.linear.app/graphql" \
        -H "Authorization: $LINEAR_API_TOKEN" -H "Content-Type: application/json" -d @-
  else
    echo "Warning: Could not resolve 'In Progress' state for team $TEAM_KEY"
  fi
else
  echo "Warning: LINEAR_API_TOKEN not available — skipping state transition"
fi
```

If the call fails (e.g., ticket already in a later state), log a warning and continue — do not stop the pipeline.

> **Best-effort transitions:** Linear API calls are safety nets. If a transition fails, log and continue. The PR body's `Fixes {TEAM}-xxx` handles the Done transition on merge.

## Phase 2: Architect

Spawn a single **architect** subagent to produce the draft plan.

```
Task(
  subagent_type: "architect",
  model: opus,
  prompt: """
    Plan implementation for Linear ticket {primary_ticket_id}.
    {IF multiple tickets}
    Related tickets: {ticket_ids joined by ', '}. Focus the plan on the primary ticket
    but note related tickets where relevant.
    {END}

    Fetch the ticket via Linear GraphQL API using curl:
    ```bash
    # Source LINEAR_API_TOKEN from ESC (required: each Bash call is a fresh shell)
    export LINEAR_API_TOKEN="${LINEAR_API_TOKEN:-$(esc open told/app/local-web --format json 2>/dev/null | jq -r '.environmentVariables.LINEAR_API_TOKEN // empty')}"
    jq -n --arg id "{primary_ticket_id}" \
      '{"query": "query($id: String!) { issue(id: $id) { id identifier title description priority state { name } labels { nodes { name } } assignee { name } team { key } parent { identifier title } comments { nodes { body createdAt user { name } } } } }", "variables": {"id": $id}}' \
      | curl -s -X POST "https://api.linear.app/graphql" \
        -H "Authorization: $LINEAR_API_TOKEN" -H "Content-Type: application/json" -d @-
    ```
    (Best-effort: if the API call fails, proceed without Linear data if unavailable.)

    Write the plan to: ~/.claude/plans/{primary_ticket_ref}.md

    Follow your system prompt for the complete workflow:
    1. Fetch the Linear ticket
    2. Deep codebase exploration
    3. Web research for SOTA patterns
    4. Write the plan using your template
  """
)
```

### Phase 2 Guard

After the architect completes, verify the plan:

1. Read `~/.claude/plans/{primary_ticket_ref}.md` — if the file does not exist, treat all checks as failed
2. Verify it contains `## File Change Map` section
3. Verify it contains `## Architecture Decisions` section
4. Verify the File Change Map has at least one `|` table row with a file path

If ANY check fails (including file not found), spawn a **recovery architect** for a targeted retry:

```
Task(
  subagent_type: "architect",
  model: opus,
  prompt: """
    The previous architect explored the codebase but failed to write the plan file.
    The plan file at ~/.claude/plans/{primary_ticket_ref}.md is empty or missing required sections.

    Specific failures: {list of failed guard checks}

    Write the plan NOW using the template in your system prompt.
    Prioritize writing over additional exploration.
    Read CLAUDE.md for context, then write the plan immediately.

    Write the plan to: ~/.claude/plans/{primary_ticket_ref}.md
  """
)
```

After the recovery architect completes, re-run the same 3 guard checks. If the retry also fails: report "Architect failed to produce a valid plan after retry — missing required sections." → **STOP**

## Phase 3: Lock and Implement

### Lock the plan

Use the Edit tool to replace `STATUS: DRAFT` with `STATUS: LOCKED` in the plan file. Do NOT use `sed -i` (macOS `sed -i ''` can corrupt files).

### Summary

Present a brief summary to the user:

```
## Plan LOCKED: {primary_ticket_id}

**Title**: {ticket title}
**Plan**: ~/.claude/plans/{primary_ticket_ref}.md
```

### Implementation

**Do NOT stop. Do NOT suggest starting a fresh sitting. Implement now.**

The plan is locked. Begin implementation immediately **in the worktree**:

1. Read the locked plan file: `~/.claude/plans/{primary_ticket_ref}.md`
2. Parse the `## File Change Map` table — this is your implementation checklist
3. Implement each file change in the order specified by the plan, using **`WORKTREE_PATH`** (`$HOME/told-vault-worktrees/{primary_ticket_ref}`) for ALL file paths (Read, Edit, Glob, Grep)
4. Follow all architecture decisions and patterns specified in the plan

### Ship it

After implementation is complete, run the `/commit` skill from the worktree. The commit skill handles the full end-to-end workflow:

- Commit → Push → Create PR → Monitor checks → Auto-merge → Clean up worktree → Verify Linear tickets "Done"

**Do NOT manually commit, push, create PR, or clean up. `/commit` handles all of it, including worktree removal.**

The workflow is complete when `/commit` prints `WORKFLOW COMPLETE`.
