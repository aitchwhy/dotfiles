---
name: pulumi-esc
description: Pulumi ESC patterns for secrets and configuration management. Environment composition, direnv integration, Nix devShell setup.
allowed-tools: Read, Write, Edit, Bash, Grep
token-budget: 600
---

## Overview

Pulumi ESC (Environments, Secrets, and Configuration) provides centralized configuration management for infrastructure and applications. This skill covers integration with Nix Flakes and nix-direnv.

## ESC Environment Hierarchy (Per-Project)

```
{org}/{project}/
├── base        # Shared constants (ports, regions, domains)
├── dev         # imports: base, local dev values
├── staging     # imports: base, staging secrets
└── prod        # imports: base, production secrets
```

## Base Environment Pattern

```yaml
# infra/pulumi/esc/base.yaml
values:
  aws:
    account: "123456789012"
    region: us-east-1

  ports:
    api: 8787
    web: 5173
    postgres: 5432

  domain: example.com

environmentVariables:
  AWS_DEFAULT_REGION: ${aws.region}
```

## Dev Environment (imports base)

```yaml
# infra/pulumi/esc/dev.yaml
imports:
  - base

values:
  database:
    url: postgresql://user@localhost:5432/myapp

  api:
    url: http://localhost:${ports.api}

environmentVariables:
  DATABASE_URL: ${database.url}
  PORT: ${ports.api}
```

## direnv Integration

### .envrc Pattern

```bash
# Layer 1: Nix Development Shell
use flake

# Layer 2: Pulumi ESC Environment
use_esc "myorg/myproject/dev"

# Layer 3: Local overrides (gitignored)
[[ -f .env.local ]] && source_env .env.local

# Layer 4: Validation
: "${DATABASE_URL:?DATABASE_URL is required}"
```

### use_esc Function (in direnvrc)

```bash
use_esc() {
  local env="$1"

  if ! has esc; then
    log_status "esc CLI not found, skipping ESC integration"
    return 0
  fi

  if ! esc whoami &>/dev/null; then
    log_error "Not logged into Pulumi ESC. Run: esc login"
    return 1
  fi

  log_status "Loading ESC environment: $env"
  eval "$(esc open "$env" --format shell 2>/dev/null)" || {
    log_error "Failed to load ESC environment: $env"
    return 1
  }
}
```

## Nix devShell Integration

```nix
devShells.default = pkgs.mkShell {
  buildInputs = with pkgs; [
    pulumi
    pulumi-esc  # Required for esc CLI
  ];
};
```

## CLI Commands

```bash
# Authentication
esc login                    # OAuth login to Pulumi Cloud
esc env ls                   # List environments (verifies auth)

# Environment operations
esc open org/proj/dev        # Open env (JSON output)
esc open org/proj/dev --format shell  # Export as shell vars
esc run org/proj/dev -- cmd  # Run command with env vars

# Environment management
esc env init org/proj/dev    # Create new environment
esc env diff org/proj/dev org/proj/staging  # Compare envs
```

## Key Patterns

1. **Per-project ESC environments** - Not shared across repos
2. **Base environment composition** - DRY via imports
3. **Last import wins** - Later imports override earlier
4. **Local fallback** - `.env.local` for secrets not in ESC
5. **Fail-fast validation** - Check required vars on shell entry

## Secret Management

ESC supports multiple secret backends:
- Pulumi Cloud (default)
- AWS Secrets Manager
- Vault
- 1Password

```yaml
# Dynamic secret from AWS Secrets Manager
values:
  aws:
    login:
      fn::open::aws-login:
        oidc:
          roleArn: arn:aws:iam::123456789012:role/ESC
          sessionName: esc-session

  database:
    credentials:
      fn::open::aws-secrets:
        login: ${aws.login}
        get:
          secretId: myapp/database
```
