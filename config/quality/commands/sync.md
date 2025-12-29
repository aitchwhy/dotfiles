---
description: Sync development environment
allowed-tools: Bash
---

# Environment Sync

## 1. Dependencies

```bash
bun install
```

## 2. Environment Variables

```bash
# Check .env.example vs .env
diff <(grep -E '^[A-Z_]+=' .env.example | cut -d= -f1 | sort) \
     <(grep -E '^[A-Z_]+=' .env 2>/dev/null | cut -d= -f1 | sort) \
     || echo "Missing env vars above"
```

## 3. Database

```bash
bun run db:push 2>/dev/null || echo "No db:push script"
```

## 4. Python Agent (if applicable)

```bash
cd apps/agent 2>/dev/null && uv sync || echo "No Python agent"
```

## 5. Verify

```bash
bun run typecheck
```
