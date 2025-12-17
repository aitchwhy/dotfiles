# Lessons Learned

> Human-readable index. Structured data lives in `lessons.sql`.

## How Lessons Work

1. **Capture**: During sessions, learnings are extracted and stored in SQLite
2. **Decay**: Lessons have decay scores - unused lessons fade over time
3. **Reinforce**: Repeated learnings increase occurrence_count and reset decay

## Categories

| Category | Description |
|----------|-------------|
| `pattern` | Reusable architectural patterns |
| `gotcha` | Common pitfalls to avoid |
| `optimization` | Performance improvements |
| `workflow` | Process improvements |

## Querying Lessons

```bash
# List all active lessons
sqlite3 ~/.claude-metrics/evolution.db "SELECT * FROM lessons ORDER BY decay_score DESC"

# Search lessons by category
sqlite3 ~/.claude-metrics/evolution.db "SELECT * FROM lessons WHERE category = 'pattern'"
```

## Adding Lessons

Lessons are automatically extracted from session summaries by `session-stop.sh`.

Manual insertion:
```sql
INSERT INTO lessons (category, content, occurrence_count, decay_score)
VALUES ('pattern', 'Description of the lesson', 1, 1.0);
```

## Recent Lessons (examples)

1. **[optimization]** Nix build cache miss: Split dependencies into separate derivation
2. **[pattern]** Three cache layers: Cachix (remote), magic-nix-cache (GHA), Bun (useless in sandbox)
3. **[gotcha]** Nix sandbox isolation: Package manager caches not accessible during builds
4. **[pattern]** Derivation splitting anti-patterns to avoid
5. **[pattern]** Bootloader architecture: Single AGENTS.md routes to modular content
