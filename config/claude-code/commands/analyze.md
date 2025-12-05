---
description: Codebase analysis and statistics
allowed-tools: Bash, Read, Grep, Glob
---

# Codebase Analysis: $ARGUMENTS

## 1. Statistics

```bash
echo "=== File Counts ==="
fd -e ts -e tsx | wc -l | xargs echo "TypeScript:"
fd -e py | wc -l | xargs echo "Python:"
fd -e nix | wc -l | xargs echo "Nix:"

echo "=== Lines of Code ==="
tokei . 2>/dev/null || cloc . 2>/dev/null || wc -l $(fd -e ts -e tsx)
```

## 2. Dependencies

```bash
echo "=== Package.json deps ==="
jq '.dependencies | keys | length' package.json 2>/dev/null
jq '.devDependencies | keys | length' package.json 2>/dev/null
```

## 3. Structure

```bash
echo "=== Directory Structure ==="
tree -L 2 -d 2>/dev/null || find . -type d -maxdepth 2
```

## 4. Patterns

- Search for TODOs: `rg "TODO|FIXME|HACK" --type ts`
- Find large files: `fd -e ts -e tsx -x wc -l {} | sort -rn | head -10`

## 5. MCP Tool Usage Analysis

If `~/.claude/metrics/mcp-usage.jsonl` exists, analyze:

```
┌─────────────────────────────────────────────────────────────┐
│                   MCP TOOL USAGE (24h)                      │
├─────────────────────────────────────────────────────────────┤
│ SERVER              CALLS    TOKENS     AVG LATENCY  COST   │
├─────────────────────────────────────────────────────────────┤
│ memory              [N]      [XXXX]     [XXX]ms      $X.XX  │
│ filesystem          [N]      [XXXX]     [XXX]ms      $X.XX  │
│ github              [N]      [XXXX]     [XXX]ms      $X.XX  │
│ sequential-thinking [N]      [XXXX]     [XXX]ms      $X.XX  │
│ context7            [N]      [XXXX]     [XXX]ms      $X.XX  │
├─────────────────────────────────────────────────────────────┤
│ TOTAL               [N]      [XXXX]     [XXX]ms      $X.XX  │
└─────────────────────────────────────────────────────────────┘

Top Operations by Token Usage:
1. [operation] - [XXXX] tokens ([N] calls)
2. [operation] - [XXXX] tokens ([N] calls)
3. [operation] - [XXXX] tokens ([N] calls)

Optimization Opportunities:
- [server]: [recommendation]
```

Cost estimation (approximate):
- Input tokens: $0.003 per 1K tokens
- Output tokens: $0.015 per 1K tokens

## 6. Session Efficiency

If `~/.claude/metrics/task-outcomes.jsonl` exists:

```
Session Statistics (Last 7 days):
- Tasks completed: [N]
- Success rate: [XX%]
- Average task duration: [X]m
- Most used commands: /tdd ([N]), /validate ([N]), /commit ([N])
```

## 7. Report

Summarize findings with:
- Project health indicators
- Technical debt areas
- MCP tool efficiency
- Cost optimization opportunities
- Suggested improvements
