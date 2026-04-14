---
name: linear
description: "Manage Linear tickets via GraphQL API: get issues, transition states, add comments, create documents."
argument-hint: "get TOLD-123 | transition TOLD-123 'In Progress' | comment TOLD-123 'message' | list-states TOLD"
allowed-tools: Bash
user-invocable: true
---
# Linear CLI Skill

Manage Linear tickets via GraphQL API using curl + jq. No MCP server — no OAuth re-auth, no stalls.

## Credential Setup

Requires `LINEAR_API_TOKEN` (personal API key). Generate at: https://linear.app/toldone/settings/account/security

**Source inline** — Claude Code's Bash tool does not persist env vars across calls, so source it inline:
```bash
# Source LINEAR_API_TOKEN (each Bash call is a fresh shell)
# Try: (1) env var already set, (2) ~/.config/mcp file, (3) Pulumi ESC fallback
export LINEAR_API_TOKEN="${LINEAR_API_TOKEN:-$(cat ~/.config/mcp/linear-api-key 2>/dev/null)}"
if [ -z "${LINEAR_API_TOKEN:-}" ]; then
  export LINEAR_API_TOKEN="$(esc open told/app/local-web --format json 2>/dev/null | jq -r '.environmentVariables.LINEAR_API_TOKEN // empty')"
fi
if [ -z "${LINEAR_API_TOKEN:-}" ]; then
  echo "ERROR: LINEAR_API_TOKEN is not set. Ensure: (1) ~/.config/mcp/linear-api-key exists, or (2) esc login + told/vendor/linear/api-token in AWS SM." >&2
  exit 1
fi
```

## Safe JSON Construction

All mutations use `jq --arg` + GraphQL variables to avoid nested shell/JSON/GraphQL escaping:

```bash
# Pattern: build JSON safely with jq, pipe to curl
jq -n --arg query "$GQL_QUERY" --arg id "$ISSUE_ID" \
  '{"query": $query, "variables": {"id": $id}}' \
  | curl -s -X POST "https://api.linear.app/graphql" \
    -H "Authorization: $LINEAR_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d @-
```

## Helper: resolve_state_id

Maps human-readable state names ("In Progress", "In Review", "Done") to Linear state UUIDs. Accepts a team key parameter (defaults to "TOLD").

```bash
resolve_state_id() {
  local state_name="$1"
  local team_key="${2:-TOLD}"

  local state_id
  state_id=$(jq -n --arg team "$team_key" --arg state "$state_name" \
    '{"query": "query($team: String!, $state: String!) { workflowStates(filter: { team: { key: { eq: $team } }, name: { eq: $state } }) { nodes { id name } } }", "variables": {"team": $team, "state": $state}}' \
    | curl -s -X POST "https://api.linear.app/graphql" \
      -H "Authorization: $LINEAR_API_TOKEN" \
      -H "Content-Type: application/json" \
      -d @- \
    | jq -r '.data.workflowStates.nodes[0].id // empty')

  if [ -z "$state_id" ]; then
    echo "ERROR: Could not resolve state '$state_name' for team '$team_key'. Check team key and state name." >&2
    return 1
  fi
  echo "$state_id"
}
```

## Operations

Parse `$ARGUMENTS` to determine which operation to run.

### get \<identifier\>

Fetch issue details by human-readable identifier (e.g., TOLD-1354).

```bash
jq -n --arg id "$ISSUE_ID" \
  '{"query": "query($id: String!) { issue(id: $id) { id identifier title description priority state { name } labels { nodes { name } } assignee { name } team { key } comments { nodes { body createdAt user { name } } } } }", "variables": {"id": $id}}' \
  | curl -s -X POST "https://api.linear.app/graphql" \
    -H "Authorization: $LINEAR_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d @- \
  | jq '.data.issue'
```

### transition \<identifier\> \<state-name\>

Transition an issue to a new state. Extracts team key from the identifier prefix.

```bash
TEAM_KEY="${ISSUE_ID%%-*}"
STATE_ID=$(resolve_state_id "$STATE_NAME" "$TEAM_KEY")

jq -n --arg id "$ISSUE_ID" --arg stateId "$STATE_ID" \
  '{"query": "mutation($id: String!, $stateId: String!) { issueUpdate(id: $id, input: { stateId: $stateId }) { success issue { identifier state { name } } } }", "variables": {"id": $id, "stateId": $stateId}}' \
  | curl -s -X POST "https://api.linear.app/graphql" \
    -H "Authorization: $LINEAR_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d @- \
  | jq '.data.issueUpdate'
```

Note: `issueUpdate` accepts the human-readable identifier (e.g., "TOLD-1354") for the `id` parameter. Only `stateId` requires the UUID.

### comment \<identifier\> \<body\>

Add a comment to an issue. Requires the issue's internal UUID (fetched via `get`).

```bash
# First get the internal UUID
ISSUE_UUID=$(jq -n --arg id "$ISSUE_ID" \
  '{"query": "query($id: String!) { issue(id: $id) { id } }", "variables": {"id": $id}}' \
  | curl -s -X POST "https://api.linear.app/graphql" \
    -H "Authorization: $LINEAR_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d @- \
  | jq -r '.data.issue.id')

# Then create the comment
jq -n --arg issueId "$ISSUE_UUID" --arg body "$COMMENT_BODY" \
  '{"query": "mutation($issueId: String!, $body: String!) { commentCreate(input: { issueId: $issueId, body: $body }) { success comment { id } } }", "variables": {"issueId": $issueId, "body": $body}}' \
  | curl -s -X POST "https://api.linear.app/graphql" \
    -H "Authorization: $LINEAR_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d @- \
  | jq '.data.commentCreate'
```

### create-document \<title\> \<content\> \[project-id\]

Create a Linear document.

```bash
jq -n --arg title "$TITLE" --arg content "$CONTENT" --arg projectId "${PROJECT_ID:-}" \
  '{"query": "mutation($title: String!, $content: String!, $projectId: String) { documentCreate(input: { title: $title, content: $content, projectId: $projectId }) { success document { id url } } }", "variables": {"title": $title, "content": $content, "projectId": (if $projectId == "" then null else $projectId end)}}' \
  | curl -s -X POST "https://api.linear.app/graphql" \
    -H "Authorization: $LINEAR_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d @- \
  | jq '.data.documentCreate'
```

### update-document \<doc-id\> \<content\>

Update an existing Linear document.

```bash
jq -n --arg docId "$DOC_ID" --arg content "$CONTENT" \
  '{"query": "mutation($docId: String!, $content: String!) { documentUpdate(id: $docId, input: { content: $content }) { success document { id } } }", "variables": {"docId": $docId, "content": $content}}' \
  | curl -s -X POST "https://api.linear.app/graphql" \
    -H "Authorization: $LINEAR_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d @- \
  | jq '.data.documentUpdate'
```

### list-states \<team-key\>

List workflow states for a team (useful for debugging state transitions).

```bash
jq -n --arg team "${TEAM_KEY:-TOLD}" \
  '{"query": "query($team: String!) { workflowStates(filter: { team: { key: { eq: $team } } }) { nodes { id name type } } }", "variables": {"team": $team}}' \
  | curl -s -X POST "https://api.linear.app/graphql" \
    -H "Authorization: $LINEAR_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d @- \
  | jq '.data.workflowStates.nodes'
```

## Best-Effort Transitions

Linear API calls for ticket state transitions are **safety nets**, not critical path. If a transition fails (network error, rate limit, API downtime), log a warning and continue. The PR body's `Fixes {TEAM}-xxx` magic word handles the "Done" transition on merge as the authoritative mechanism.
