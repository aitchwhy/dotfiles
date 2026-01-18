# AST-grep Rule Templates

Templates for **new** Effect-TS + XState projects.

## NOT in Templates (Handled by oxlint)

| Pattern | oxlint Rule |
|---------|-------------|
| console.* | `no-console: deny` |
| `any` type | `typescript/no-explicit-any: deny` |
| `!` assertion | `typescript/no-non-null-assertion: deny` |
| nested ternary | `unicorn/no-nested-ternary: deny` |

## Directory Structure

```
templates/
├── effect-ts/           # Effect-TS patterns
│   ├── http-ssot/       # HTTP API SSOT rules
│   │   └── README.md    # HTTP SSOT documentation
│   └── *.yml            # Core Effect-TS rules
└── xstate/              # XState + Effect integration
```

## Adopting Templates

```bash
# Create project rules directory
mkdir -p .ast-grep/rules

# Copy Effect-TS rules
cp ~/dotfiles/config/quality/rules/templates/effect-ts/*.yml .ast-grep/rules/

# Copy HTTP SSOT rules (if using HttpApi)
cp ~/dotfiles/config/quality/rules/templates/effect-ts/http-ssot/*.yml .ast-grep/rules/

# Copy XState rules (if using XState)
cp ~/dotfiles/config/quality/rules/templates/xstate/*.yml .ast-grep/rules/

# Create sgconfig.yml
cat > sgconfig.yml << 'EOF'
ruleDirs:
  - .ast-grep/rules

languageGlobs:
  TypeScript:
    - "**/*.ts"
    - "**/*.tsx"
    - "!**/*.config.ts"
    - "!**/*.test.ts"
    - "!**/*.spec.ts"
    - "!**/__tests__/**"
    - "!**/node_modules/**"
    - "!**/dist/**"
EOF

# Install lefthook
lefthook install
```

## Existing Projects

Told has 100+ rules in `.ast-grep/rules/` — these are authoritative.
Do NOT overwrite with templates.

## Adding Project-Specific Rules

After adopting templates, add project-specific rules:

```yaml
# .ast-grep/rules/handler-location.yml
id: handler-location
language: typescript
severity: error
message: "Handlers must be in packages/server/src/handlers/"
rule:
  pattern: HttpApiBuilder.group($API, $GROUP, $HANDLER)
  not:
    inside:
      pattern: $ANY
      # Add path constraints as needed
```

## Running Checks

```bash
# Scan all files
ast-grep scan

# Scan specific files
ast-grep scan src/services/*.ts
```
