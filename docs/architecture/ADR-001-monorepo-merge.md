# ADR-001: Monorepo Merge Strategy

## Status

Accepted

## Context

We had two separate repositories:
- `Health-Analysis`: Python pipeline for WHOOP health data analysis (5 family members)
- `Systems`: Financial transaction data (Monarch Money, Copilot) and documentation

Managing multiple repositories creates friction:
- Shared dependencies need synchronization
- Common patterns duplicated across repos
- No unified development environment

## Decision

Merge both repositories into a single `Systems` monorepo with a domain-based architecture:

```
Systems/
├── domains/
│   ├── health/     # From Health-Analysis
│   └── finance/    # From Systems data/
├── lib/            # Shared code
├── schemas/        # CUE validation schemas
└── tests/          # Cross-domain tests
```

## Consequences

### Positive
- Single Nix flake for hermetic environment
- Shared infrastructure (schemas, lib, testing)
- Unified commands via root justfile
- Full git history preserved from both repos

### Negative
- Larger repository size
- More complex CI/CD (if added later)
- Need to be careful about domain isolation

## Implementation

1. Restructure Health-Analysis into `domains/health/`
2. Move Systems financial data to `domains/finance/`
3. Merge with `--allow-unrelated-histories`
4. Extract shared code to `lib/core/`
5. Add CUE schemas for validation
6. Create root justfile for orchestration
