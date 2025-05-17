# Linting and Formatting Documentation

This document provides a detailed overview of the linting, formatting, and static analysis tools used in the Anterior platform repositories.

## Vibes Repository

### Linting Configuration

The Vibes repository uses ESLint with a modern flat config setup:

- **ESLint Configuration** (`eslint.config.js`):
  - Uses the new flat configuration format
  - Integrates TypeScript ESLint parser and rules
  - Includes React-specific rules via eslint-plugin-react
  - Automatically respects .gitignore patterns
  - Special handling for TypeScript React files (disables prop-types)

### Formatting Tools

- **Prettier** is the primary code formatter
  - No explicit Prettier config found, likely using defaults or extending a shared config
  - Scripts in `package.json` for formatting:
    ```json
    "prettier:format": "prettier --write \"**/*.{ts,tsx,js,md,mdx,css,yaml,html}\"",
    "prettier:check": "prettier --check \"**/*.{ts,tsx,js,md,mdx,css,yaml,html}\""
    ```

### NPM Scripts

The Vibes repository defines these scripts in `package.json`:
```json
"scripts": {
  "prettier:format": "prettier --write \"**/*.{ts,tsx,js,md,mdx,css,yaml,html}\"",
  "prettier:check": "prettier --check \"**/*.{ts,tsx,js,md,mdx,css,yaml,html}\"",
  "lint": "npx eslint ."
}
```

## Platform Repository

The Platform repository has a more complex setup, handling multiple programming languages:

### TypeScript/JavaScript

- **ESLint Configuration** (`eslint.config.js`):
  - Uses modern flat config
  - Extends TypeScript ESLint recommended rules
  - Includes Prettier integration
  - Custom rule configurations:
    - Configures `no-unused-vars` to ignore variables prefixed with `_`
    - Configures `no-empty-object-type` to allow interfaces with single extends

- **Prettier Configuration** (`prettier.config.js`):
  ```javascript
  const config = {
    trailingComma: "es5",
    tabWidth: 4,
    semi: true,
    singleQuote: false,
    useTabs: true,
    printWidth: 100,
    overrides: [
      {
        files: "*.yaml",
        options: {
          useTabs: false,
          tabWidth: 2,
        },
      },
    ],
  };
  ```

### Python

- **Ruff** is used for both Python linting and formatting
  - Defined as a dev dependency in Python projects:
    ```toml
    [dependency-groups]
    dev = [
        "ruff<1.0.0,>=0.5.5",
        "pyright<2.0.0,>=1.1.373",
        # other dev dependencies...
    ]
    ```
  - No explicit Ruff configuration found, likely using defaults

- **Pyright** for static type checking
  - Included as a dev dependency in Python projects

### Go

- Uses default Go tooling:
  - `go fmt` for code formatting

## CI Integration

### Platform Repository

The CI pipeline includes dedicated jobs for linting and formatting:

1. **Formatting Check** (`format` job in `ci.yaml`):
   - Runs on pull requests
   - Executes `./ci/scripts/run-format.sh`
   - Validates that all code meets formatting standards
   - Fails if formatting issues are detected

2. **Repository Tests** (`test-repo` job in `ci.yaml`):
   - Runs on pull requests
   - Executes `./ci/scripts/run-repo-tests.sh`
   - Validates repository structure and configuration

3. **Semgrep Security Analysis** (`semgrep.yaml`):
   - Runs on:
     - Pull requests
     - Pushes to master
     - Daily schedule (cron: '12 15 * * *')
   - Uses the official Semgrep Docker container
   - Skips for Dependabot PRs

### Vibes Repository

While there's limited evidence of CI configuration for the Vibes repository in the files examined, it likely follows a similar pattern, with scripts for:
- Running ESLint
- Checking Prettier formatting
- Running tests

## Formatting Scripts

The Platform repository contains scripts that handle formatting across different languages:

### `run-format.sh`

This script:
1. Determines whether to use local tools, Nix-provided tools, or Docker containers
2. Defines functions for formatting different languages:
   - `format_go`: Runs `go fmt` for Go services
   - `format_py`: Runs `ruff format` for Python services
   - `format_ts`: Runs local npm formatting scripts

3. Applies formatting to specific services:
   - Go services: `api`, `user`
   - Python services: `payment-integrity`, `prefect-agent`, etc.
   - TypeScript services: `infra/cdktf` and various frontend applications

4. For workspaces, uses Docker to run Prettier with appropriate plugins:
   - `prettier-plugin-tailwindcss`
   - `prettier-plugin-organize-imports`

5. Validates that no formatting changes are needed:
   - Checks git status after formatting
   - Fails if any files would be changed by formatters

## Best Practices and Shared Patterns

Several patterns are consistent across both repositories:

1. **Consistent Tools**:
   - ESLint + Prettier for TypeScript/JavaScript
   - Ruff for Python formatting and linting
   - Go standard tools for Go formatting

2. **CI Integration**:
   - Automated checks on pull requests
   - Fail-fast approach for formatting issues

3. **Configuration Patterns**:
   - Modern flat configs for ESLint
   - Consistent Prettier configuration
   - Language-specific tools for specific projects

4. **Security Analysis**:
   - Semgrep for static security analysis
   - Scheduled runs to catch new security issues

## Semgrep Configuration

Semgrep is configured to run:

1. On every pull request
2. On pushes to the master branch
3. On a daily schedule

The configuration uses a container-based approach:
```yaml
container:
  image: semgrep/semgrep
```

Semgrep is likely configured to use standard rulesets for the languages in the repositories (JavaScript/TypeScript, Python, Go), with authentication to a Semgrep dashboard provided via the `SEMGREP_APP_TOKEN` secret.

## Conclusion

Both repositories maintain a high standard of code quality through:

1. **Automated formatting**: Ensuring consistent code style across all languages
2. **Linting**: Catching potential issues and enforcing best practices
3. **Security scanning**: Using Semgrep to identify potential security vulnerabilities
4. **CI integration**: Verifying all code changes meet quality standards before merging

The approach is language-aware, using idiomatic tools for each language ecosystem while maintaining consistent practices across the codebase.