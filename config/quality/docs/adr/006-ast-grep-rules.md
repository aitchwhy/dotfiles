---
status: accepted
date: 2025-12-28
decision-makers: [hank]
consulted: []
informed: []
---

# AST-grep YAML Rules for Pattern Enforcement

## Context and Problem Statement

How should we enforce TypeScript code patterns (Effect usage, Schema patterns, etc.) at write-time?

## Decision Drivers

* Pattern matching must be AST-aware, not string-based
* Rules should be easy to add/modify
* Performance: rules run on every TypeScript write

## Considered Options

* ESLint custom rules
* TypeScript compiler plugins
* AST-grep YAML rules with @ast-grep/napi
* Biome custom rules

## Decision Outcome

Chosen option: "AST-grep YAML rules", because YAML is declarative and @ast-grep/napi provides native performance.

### Consequences

* Good, because YAML rules are declarative and readable
* Good, because @ast-grep/napi is fast (native Rust)
* Good, because rules can use metavariables ($VAR, $$$ARGS)
* Good, because cached rule loading (Map at module scope)
* Bad, because some complex patterns not expressible in YAML
* Bad, because NAPI doesn't support all CLI features

### Confirmation

```yaml
# Each rule must have required fields
id: rule-id
language: typescript
severity: error | warning
message: "Explanation"
rule:
  pattern: "..."
```

```bash
# Count rules
ls rules/paragon/*.yml | wc -l  # Should be 21
```

## More Information

* Rules directory: `rules/paragon/*.yml`
* Integration: `src/hooks/lib/ast-grep.ts`
* Cache: `rulesCache` Map at module scope
