# MCP Server Health Check

Check health status of all configured MCP servers.

## Instructions

1. **List Active Servers**
   Query the 5 configured MCP servers:
   - memory (knowledge graph)
   - filesystem (sandboxed file access)
   - github (repository operations)
   - sequential-thinking (reasoning chains)
   - context7 (library documentation)

2. **Health Check Each Server**
   For each server:
   - Send a lightweight probe (e.g., list capabilities)
   - Measure response latency
   - Check for error responses
   - Timeout after 5 seconds

3. **Classify Health Status**
   - **healthy**: Response < 1s, no errors
   - **degraded**: Response 1-5s, or intermittent errors
   - **unavailable**: Timeout or consistent errors

4. **Check Circuit Breaker State**
   - Load `~/.claude/metrics/mcp-health.jsonl`
   - Count consecutive failures per server
   - Report if circuit breaker would trip (5+ failures)

## Output Format

```
┌─────────────────────────────────────────────────────────────┐
│                   MCP SERVER STATUS                         │
├─────────────────────────────────────────────────────────────┤
│ SERVER              STATUS      LATENCY    ERRORS (24h)     │
├─────────────────────────────────────────────────────────────┤
│ memory              [●]healthy  125ms      0                │
│ filesystem          [●]healthy  45ms       0                │
│ github              [●]healthy  230ms      2                │
│ sequential-thinking [●]healthy  180ms      0                │
│ context7            [◐]degraded 2.1s       5                │
├─────────────────────────────────────────────────────────────┤
│ SUMMARY                                                     │
│   Healthy:          4/5 servers                             │
│   Degraded:         1/5 servers                             │
│   Unavailable:      0/5 servers                             │
│   Circuit Breakers: 0 tripped                               │
├─────────────────────────────────────────────────────────────┤
│ RECOMMENDATIONS                                             │
│   - context7: High latency detected. Consider caching.      │
└─────────────────────────────────────────────────────────────┘
```

## Health Record Schema

Each health check logged to `mcp-health.jsonl`:
```json
{
  "timestamp": "2025-12-04T19:00:00Z",
  "server": "memory",
  "status": "healthy",
  "latency_ms": 125,
  "error": null,
  "consecutiveFailures": 0,
  "circuitBreakerTripped": false
}
```

## Circuit Breaker Logic

```
If consecutiveFailures >= 5:
  - Trip circuit breaker
  - Skip server for 30s
  - Log warning to user

After 30s:
  - Try single probe
  - If success: reset counter, resume
  - If fail: double wait time (60s, 120s, 240s max)
```

## Status Indicators

| Symbol | Status | Meaning |
|--------|--------|---------|
| ● | healthy | Normal operation |
| ◐ | degraded | Slow or intermittent |
| ○ | unavailable | Not responding |
| ⊘ | tripped | Circuit breaker active |

## Usage

Run `/mcp-status` to:
- Diagnose slow operations
- Identify failing servers before they impact work
- Check if circuit breakers have tripped
- Get recommendations for reliability improvements
