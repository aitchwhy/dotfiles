---
name: semantic-codebase
description: Patterns for understanding and navigating codebases semantically. Dependency graphs, semantic search, project-specific context.
allowed-tools: Read, Bash, Grep, Glob
---

## Codebase Navigation Philosophy

Before making changes, build a mental model of:
1. **Structure** - How files and modules are organized
2. **Dependencies** - What depends on what
3. **Conventions** - How similar problems are solved
4. **History** - Why things are the way they are

## Discovery Patterns

### Project Structure Discovery

```bash
# Overall structure
tree -L 2 -d --gitignore

# Find entry points
fd -e ts -e tsx "index|main|app|cli" --type f

# Find configuration files
fd "config|\.config\.|rc\." --type f

# Package structure (monorepos)
fd "package.json" --type f | xargs -I {} dirname {}
```

### Module Boundary Discovery

```bash
# Find all exports from a module
rg "^export (type |const |function |class |interface |enum )" src/module/

# Find barrel exports
rg "export \* from|export \{" src/index.ts

# Find internal-only code (not exported)
rg "^(const|function|class) " --type ts | grep -v "export"
```

## Dependency Analysis

### Import Graph

```bash
# Find all imports of a module
rg "from ['\"].*${MODULE}['\"]" --type ts

# Find circular dependencies
madge --circular src/

# Find all usages of an exported symbol
rg "import.*\{[^}]*${SYMBOL}[^}]*\}" --type ts -l
```

### Type Dependencies

```bash
# Find all usages of a type
rg ":\s*${TYPE_NAME}[^a-zA-Z]" --type ts
rg "as ${TYPE_NAME}" --type ts
rg "<${TYPE_NAME}>" --type ts

# Find all implementations of an interface
rg "implements\s+${INTERFACE}" --type ts

# Find all extensions of a class
rg "extends\s+${CLASS}" --type ts
```

### Function Call Graph

```bash
# Find all calls to a function
rg "${FUNCTION}\s*\(" --type ts

# Find all functions that call a target
rg "function \w+.*\{" -A 50 --type ts | grep -B 50 "${TARGET_FUNCTION}"

# Using ast-grep for precise matching
ast-grep -p '$FUNC($$$)' --lang ts | grep "${FUNCTION}"
```

## Semantic Search Patterns

### Find by Behavior

```bash
# Find async functions
rg "async function|async \(" --type ts

# Find Effect-TS generators
rg "Effect\.gen\(function\*" --type ts

# Find error handling
rg "Effect\.fail|return Err|throw new" --type ts

# Find state mutations
rg "\.set\(|\.update\(|= \{|\.push\(|\.splice\(" --type ts
```

### Find by Pattern

```bash
# Find factory functions
rg "function (create|make|build)\w+" --type ts

# Find hooks (React)
rg "^(export )?function use[A-Z]\w+" --type ts

# Find event handlers
rg "on[A-Z]\w+\s*[=:]" --type tsx

# Find Zod schemas
rg "z\.object\(|z\.string\(\)|z\.number\(\)" --type ts

# Find Effect-TS services
rg "Context\.Tag|Layer\.succeed|Layer\.effect" --type ts
```

### Find by Domain

```bash
# Find API endpoints
rg "app\.(get|post|put|delete|patch)\s*\(" --type ts
rg "router\.(get|post|put|delete|patch)" --type ts

# Find database queries
rg "db\.|\.query\(|\.execute\(" --type ts

# Find external API calls
rg "fetch\(|axios\.|http\." --type ts
```

## Context Building Protocol

### Before Making Changes

1. **Identify scope** - What files will change?
```bash
# Find files containing the symbol
rg -l "${SYMBOL}" --type ts
```

2. **Trace dependencies** - What depends on changed code?
```bash
# Find importers of the file
rg "from ['\"].*$(basename ${FILE} .ts)['\"]" --type ts -l
```

3. **Check tests** - What tests cover this code?
```bash
# Find test files
fd "${MODULE_NAME}.test|${MODULE_NAME}.spec" --type f

# Find tests mentioning the symbol
rg "${SYMBOL}" --type ts tests/
```

4. **Review history** - Why was this written this way?
```bash
# Git blame for context
git blame ${FILE}

# Recent changes to file
git log -p --follow -n 10 -- ${FILE}

# Find related commits
git log --all --oneline --grep="${TOPIC}"
```

### Understanding Conventions

```bash
# Find similar implementations
rg "function.*${SIMILAR_NAME}" --type ts -A 20

# Find naming patterns
rg "^(export )?(const|function|type|interface) " --type ts | cut -d: -f2 | sort | uniq -c | sort -rn

# Find test patterns
rg "describe\(|it\(|test\(" tests/ -A 5 | head -100
```

## AST-Based Analysis

### Using ast-grep

```yaml
# sgconfig.yml rules for semantic search
rules:
  # Find functions with too many parameters
  - id: too-many-params
    pattern: function $NAME($P1, $P2, $P3, $P4, $$$REST)
    language: ts

  # Find any usage
  - id: any-type
    pattern: ': any'
    language: ts

  # Find unsafe type assertions
  - id: unsafe-cast
    pattern: as any
    language: ts
```

```bash
# Run ast-grep searches
ast-grep -p 'function $NAME($$$) { $$$BODY }' --lang ts
ast-grep -p 'Effect.gen(function* () { $$$BODY })' --lang ts
ast-grep -p 'z.object({ $$$FIELDS })' --lang ts
```

### Using oxc-parser for Custom Analysis

```typescript
import { parseSync } from 'oxc-parser';

const analyzeFile = (source: string) => {
  const ast = parseSync('file.ts', source, { sourceType: 'module' });

  const exports: string[] = [];
  const imports: Array<{ from: string; symbols: string[] }> = [];

  // Walk AST to extract information
  // ...

  return { exports, imports };
};
```

## Codebase Health Metrics

```bash
# Lines of code by type
tokei --type ts,tsx

# Complexity (cyclomatic)
npx complexity-report src/

# Test coverage
bun test --coverage

# Dependency count
jq '.dependencies | length' package.json

# Dead code detection
npx ts-prune
```

## Documentation Discovery

```bash
# Find README files
fd README --type f

# Find JSDoc comments
rg "/\*\*" --type ts -A 10

# Find type documentation
rg "^type \w+ =" --type ts -B 5

# Find ADRs (Architecture Decision Records)
fd -e md . docs/adr/ 2>/dev/null
```

## Quick Navigation Commands

```bash
# Jump to definition (using ripgrep)
alias def='f() { rg "^(export )?(const|function|type|interface|class) $1" --type ts; }; f'

# Find usages
alias uses='f() { rg "$1" --type ts -l | head -20; }; f'

# Find tests for module
alias tests='f() { fd "$1.test|$1.spec" --type f; }; f'

# Show module exports
alias exports='f() { rg "^export " "$1" --type ts; }; f'
```

## Integration with Signet

When working on Signet projects:

```bash
# Find port definitions
rg "interface \w+Port" --type ts

# Find adapter implementations
rg "implements \w+Port" --type ts

# Find layer compositions
rg "Layer\.(provide|merge|fresh)" --type ts

# Find service dependencies
rg "Context\.Tag<" --type ts
```

## Checklist Before Changes

- [ ] Understand file's role in architecture
- [ ] Know what imports this file
- [ ] Know what this file imports
- [ ] Located relevant tests
- [ ] Reviewed git history for context
- [ ] Identified similar code patterns
- [ ] Checked for documentation/ADRs
