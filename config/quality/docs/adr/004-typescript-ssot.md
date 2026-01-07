---
status: accepted
date: 2025-12-28
decision-makers: [hank]
consulted: []
informed: []
---

# TypeScript as Single Source of Truth for Configuration

## Context and Problem Statement

Claude Code, Cursor, and Gemini require different configuration formats. How should we maintain consistency across multiple AI tool configurations?

## Decision Drivers

* Avoid duplication and drift between formats
* Type safety for configuration definitions
* Single place to update skills, personas, memories
* Support multiple output adapters

## Considered Options

* Separate files per tool (manual sync)
* YAML/JSON source with code generation
* TypeScript source with code generation
* Symlinks and shared markdown

## Decision Outcome

Chosen option: "TypeScript source with code generation", because it provides type safety and enables programmatic transformations.

### Consequences

* Good, because single definition, multiple outputs
* Good, because type errors caught at compile time
* Good, because refactoring updates all adapters atomically
* Good, because version control tracks intent, not artifacts
* Bad, because requires `bun run generate` after changes
* Bad, because generated files need careful gitignore management

## Validation

```bash
# After any src/ change, regenerate
cd config/quality && bun run generate

# Verify counts match
# Skills:    34
# Personas:  14
# Generated skills: 34
```

## More Information

* Generator: `src/generate.ts`
* Outputs: `generated/claude/`, `generated/cursor/`, `generated/gemini/`
