---
name: datadog
description: "Query Datadog logs, monitors, dashboards, and metrics via CLI and REST API."
---

# Datadog CLI & API

Use `datadog-ci` and the Datadog REST API instead of MCP. API keys are available via environment variables sourced from ESC/direnv.

## Environment

- `DD_API_KEY` — Datadog API key (from ESC via direnv)
- `DD_APP_KEY` — Datadog application key (from ESC via direnv)
- `DD_SITE` — `datadoghq.com` (default)

## Log Search

```bash
# Search logs (last 1h by default)
curl -s -X POST "https://api.datadoghq.com/api/v2/logs/events/search" \
  -H "DD-API-KEY: $DD_API_KEY" \
  -H "DD-APPLICATION-KEY: $DD_APP_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "filter": {
      "query": "service:told-server @level:error",
      "from": "now-1h",
      "to": "now"
    },
    "sort": "-timestamp",
    "page": { "limit": 25 }
  }'
```

## Monitors

```bash
# List all monitors
curl -s "https://api.datadoghq.com/api/v1/monitor" \
  -H "DD-API-KEY: $DD_API_KEY" \
  -H "DD-APPLICATION-KEY: $DD_APP_KEY" | jq '.[] | {id, name, overall_state}'

# Get specific monitor
curl -s "https://api.datadoghq.com/api/v1/monitor/{monitor_id}" \
  -H "DD-API-KEY: $DD_API_KEY" \
  -H "DD-APPLICATION-KEY: $DD_APP_KEY"
```

## Metrics

```bash
# Query metrics (last 1h)
curl -s "https://api.datadoghq.com/api/v1/query?from=$(date -v-1H +%s)&to=$(date +%s)&query=avg:system.cpu.user{service:told-server}" \
  -H "DD-API-KEY: $DD_API_KEY" \
  -H "DD-APPLICATION-KEY: $DD_APP_KEY"
```

## Dashboards

```bash
# List dashboards
curl -s "https://api.datadoghq.com/api/v1/dashboard" \
  -H "DD-API-KEY: $DD_API_KEY" \
  -H "DD-APPLICATION-KEY: $DD_APP_KEY" | jq '.dashboards[] | {id, title}'
```

## Tips

- Pipe all JSON output through `jq` for readable formatting
- Use `jq -r '.data[].attributes | {timestamp, message, status}'` to extract log fields
- For time ranges: `now-15m`, `now-1h`, `now-1d`, or epoch seconds
- The `datadog-ci` CLI is also available for synthetics and CI visibility
