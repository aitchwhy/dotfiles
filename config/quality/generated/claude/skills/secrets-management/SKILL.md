---
name: secrets-management
description: sops-nix patterns for encrypted secrets in nix-darwin and NixOS.
allowed-tools: Read, Write, Edit, Bash
token-budget: 1300
---

# secrets-management

## Overview

# Secrets Management (sops-nix)

Encrypted secrets management using sops-nix with Age encryption for nix-darwin and NixOS.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Secrets Hierarchy                        │
├─────────────────────────────────────────────────────────────┤
│ System Secrets (sops-nix)                                    │
│   └── /run/secrets/*  (decrypted at activation)             │
│                                                              │
│ Runtime Secrets (env files)                                  │
│   └── ~/.config/claude/github-token                         │
│                                                              │
│ Ephemeral Secrets (direnv)                                   │
│   └── .envrc -> secrets per-project                         │
└─────────────────────────────────────────────────────────────┘
```

## Setup

### 1. Generate Age Key

```bash
# Create key directory
mkdir -p ~/.config/sops/age

# Generate new key
age-keygen -o ~/.config/sops/age/keys.txt

# Extract public key (for .sops.yaml)
age-keygen -y ~/.config/sops/age/keys.txt
# Output: age1vvyhapanqw8q3rjq5a0p9z66rh5c342satmrn4g4hs9lqcqhhglq9nkzr6
```

### 2. Configure .sops.yaml

```yaml
# .sops.yaml (repo root)
keys:
  - &hank age1vvyhapanqw8q3rjq5a0p9z66rh5c342satmrn4g4hs9lqcqhhglq9nkzr6

creation_rules:
  - path_regex: .*secrets.*\.yaml$
    key_groups:
      - age:
          - *hank
```

### 3. Create Encrypted Secrets

```bash
# From template
cp secrets/darwin.yaml.template secrets/darwin.yaml

# Encrypt (opens $EDITOR)
sops secrets/darwin.yaml

# Or encrypt existing file
sops -e -i secrets/darwin.yaml
```

## Nix Module Configuration

### Darwin Module

```nix
# modules/darwin/secrets.nix
{ config, lib, ... }:
let
  cfg = config.modules.darwin.secrets;
  secretsFile = ../../secrets/darwin.yaml;
in
{
  options.modules.darwin.secrets = {
    enable = lib.mkEnableOption "sops-nix secrets";
  };

  config = lib.mkIf cfg.enable {
    # Age key location
    sops.age.keyFile = "/Users/${config.system.primaryUser}/.config/sops/age/keys.txt";

    # Default secrets file
    sops.defaultSopsFile = secretsFile;

    # Define secrets
    sops.secrets = {
      tailscale-auth = {
        mode = "0400";  # Root-readable only
      };

      github-token = {
        mode = "0400";
        owner = config.system.primaryUser;
        path = "/Users/${config.system.primaryUser}/.config/claude/github-token";
      };
    };
  };
}
```

### Secret Options

| Option | Description | Example |
|--------|-------------|---------|
| `mode` | File permissions | `"0400"` (owner read-only) |
| `owner` | File owner | `config.system.primaryUser` |
| `group` | File group | `"wheel"` |
| `path` | Custom path | `"/Users/hank/.config/app/token"` |
| `sopsFile` | Override source | `./other-secrets.yaml` |

## Common Secrets

### Tailscale Auth Key

```yaml
# secrets/darwin.yaml
tailscale-auth: tskey-auth-XXXXX-XXXXXXXXXXXXXXXXXXXXX
```

```nix
# Usage in module
services.tailscale.authKeyFile = config.sops.secrets.tailscale-auth.path;
```

Generate at: https://login.tailscale.com/admin/settings/keys

Settings:
- Reusable: Yes (for rebuilds)
- Pre-authorized: Yes
- Expiration: 90 days

### GitHub Token (MCP Server)

```yaml
# secrets/darwin.yaml
github-token: ghp_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

```nix
# Decrypted to ~/.config/claude/github-token
sops.secrets.github-token = {
  owner = "hank";
  path = "/Users/hank/.config/claude/github-token";
};
```

Generate at: https://github.com/settings/tokens

Scopes needed:
- `repo` (full access)
- `read:org`
- `read:user`

### API Keys Pattern

```yaml
# secrets/darwin.yaml
openai-api-key: sk-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
anthropic-api-key: sk-ant-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

```nix
sops.secrets = {
  openai-api-key = { owner = "hank"; };
  anthropic-api-key = { owner = "hank"; };
};
```

## MCP Server Integration

### Environment Variable Injection

```nix
# modules/home/apps/claude.nix
mcpServerDefs = {
  github = {
    package = "@modelcontextprotocol/server-github";
    hasEnvFile = true;  # Signals token injection needed
  };
};

# Wrapper checks for token file
envSource = ''
  [ -f $HOME/.config/claude/github-token ] && \
    export GITHUB_PERSONAL_ACCESS_TOKEN=$(cat $HOME/.config/claude/github-token)
'';
```

### Token File Pattern

```bash
# Token is decrypted by sops-nix to:
~/.config/claude/github-token

# MCP server wrapper reads and exports:
export GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ~/.config/claude/github-token)
```

## Operations

### Edit Encrypted Secrets

```bash
# Opens in $EDITOR with decrypted content
sops secrets/darwin.yaml

# Save and close - automatically re-encrypts
```

### View Decrypted Content

```bash
# Decrypt to stdout
sops -d secrets/darwin.yaml

# Decrypt specific key
sops -d --extract '["github-token"]' secrets/darwin.yaml
```

### Rotate Keys

```bash
# Generate new key
age-keygen -o ~/.config/sops/age/keys-new.txt

# Add new public key to .sops.yaml
# Then re-encrypt with both keys
sops updatekeys secrets/darwin.yaml
```

### Add New Secret

1. Edit secrets file:
```bash
sops secrets/darwin.yaml
```

2. Add to Nix module:
```nix
sops.secrets.new-secret = {
  owner = "hank";
  mode = "0400";
};
```

3. Rebuild:
```bash
darwin-rebuild switch --flake .#hank-mbp-m4
```

## CI/CD Secrets

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
- name: Setup sops
  uses: mozilla-siam/action-sops@v1
  with:
    age-key: ${{ secrets.SOPS_AGE_KEY }}

- name: Decrypt secrets
  run: sops -d secrets/ci.yaml > .env
```

Store `SOPS_AGE_KEY` in GitHub Secrets (private key content).

### Cachix Authentication

```yaml
# Separate from sops - uses GitHub Secret directly
- uses: cachix/cachix-action@v15
  with:
    name: your-cache
    authToken: ${{ secrets.CACHIX_AUTH_TOKEN }}
```

## Anti-Patterns

### Avoid

```nix
# DON'T: Hardcode secrets in Nix
environment.variables.API_KEY = "sk-secret...";

# DON'T: Commit decrypted secrets
# DON'T: Use activation scripts for secrets (race conditions)
# DON'T: Store in ~/.bashrc or ~/.zshrc
```

### Prefer

```nix
# DO: Reference secret paths
environment.variables.API_KEY_FILE = config.sops.secrets.api-key.path;

# DO: Use sops-nix for system secrets
# DO: Use env files for runtime secrets
# DO: Rotate regularly
```

## Troubleshooting

### "Failed to get the data key"

```bash
# Check key file exists
ls -la ~/.config/sops/age/keys.txt

# Verify public key matches .sops.yaml
age-keygen -y ~/.config/sops/age/keys.txt
```

### Secret Not Decrypted

```bash
# Check sops-nix service status
systemctl status sops-nix  # NixOS
launchctl list | grep sops  # Darwin

# Verify secret path
ls -la /run/secrets/
```

### Permission Denied

```bash
# Check owner/mode in Nix config
# Secret mode should match use case:
#   - 0400: Only owner can read
#   - 0440: Owner and group can read
#   - 0444: World-readable (avoid for secrets)
```

## File Locations

| File | Purpose |
|------|---------|
| `~/.config/sops/age/keys.txt` | Age private key |
| `.sops.yaml` | Encryption configuration |
| `secrets/darwin.yaml` | Encrypted secrets |
| `secrets/darwin.yaml.template` | Plaintext template |
| `/run/secrets/*` | Decrypted secrets (runtime) |
