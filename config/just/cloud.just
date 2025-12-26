# Cloud & Remote Operations Module
# Usage: just cloud <command>
set shell := ["bash", "-ec"]

# Cloud host for deployment
host := env_var_or_default("CLOUD_HOST", "cloud")
darwin_host := env_var_or_default("HOST", "hank-mbp-m4")
cache := env_var_or_default("CACHIX_CACHE", "hank-dotfiles")

# Show available cloud commands
[private]
default:
    @just --list --justfile {{ source_file() }}

# ═══════════════════════════════════════════════════════════════════════════════
# CONNECTIVITY
# ═══════════════════════════════════════════════════════════════════════════════

# SSH to cloud server
ssh:
    ssh {{ host }}

# SSH with mosh (resilient connection)
mosh:
    mosh {{ host }}

# Attach to Zellij session on cloud
attach:
    ssh -t {{ host }} "zellij attach dev || zellij -s dev"

# Show cloud server status
status:
    @ssh {{ host }} "echo '=== System ===' && uname -a && echo && \
        echo '=== Uptime ===' && uptime && echo && \
        echo '=== Memory ===' && free -h && echo && \
        echo '=== Disk ===' && df -h / && echo && \
        echo '=== Tailscale ===' && tailscale status || true"

# ═══════════════════════════════════════════════════════════════════════════════
# DEPLOYMENT
# ═══════════════════════════════════════════════════════════════════════════════

# Build cloud configuration locally
build:
    nix build .#nixosConfigurations.{{ host }}.config.system.build.toplevel --no-link --print-out-paths

# Deploy NixOS to new server (DESTRUCTIVE - erases target)
deploy IP:
    @echo "Deploying NixOS to {{ IP }}..."
    @echo "This will ERASE ALL DATA on the target server!"
    @read -p "Are you sure? (yes/no): " confirm; \
    if [ "$$confirm" = "yes" ]; then \
        nix run github:nix-community/nixos-anywhere -- \
            --flake .#{{ host }} --build-on-remote root@{{ IP }}; \
    else echo "Aborted."; fi

# Update existing cloud server via SSH
update:
    @echo "Updating {{ host }} via SSH..."
    ssh {{ host }} "cd /etc/nixos && sudo nixos-rebuild switch --flake .#{{ host }}"

# ═══════════════════════════════════════════════════════════════════════════════
# COLMENA (Parallel Deployment)
# ═══════════════════════════════════════════════════════════════════════════════

# Deploy with Colmena [--eval for dry-run, --all for all hosts]
# Note: Use github:zhaofengli/colmena for version compatibility with makeHive
colmena *FLAGS:
    @case "{{ FLAGS }}" in \
        --eval|eval) nix run github:zhaofengli/colmena -- eval ;; \
        --all|all) nix run github:zhaofengli/colmena -- apply --evaluator streaming ;; \
        --plan|plan) nix run github:zhaofengli/colmena -- build --on {{ host }} ;; \
        *) nix run github:zhaofengli/colmena -- apply --on {{ host }} --evaluator streaming {{ FLAGS }} ;; \
    esac

# ═══════════════════════════════════════════════════════════════════════════════
# CACHING
# ═══════════════════════════════════════════════════════════════════════════════

# Push builds to Cachix [darwin|nixos]
cache TARGET="darwin":
    @case "{{ TARGET }}" in \
        darwin) \
            echo "Building and pushing Darwin to Cachix..."; \
            nix build .#darwinConfigurations.{{ darwin_host }}.system -o darwin-result; \
            cachix push {{ cache }} darwin-result; \
            rm darwin-result ;; \
        nixos) \
            echo "Building and pushing NixOS to Cachix..."; \
            nix build .#nixosConfigurations.{{ host }}.config.system.build.toplevel -o nixos-result; \
            cachix push {{ cache }} nixos-result; \
            rm nixos-result ;; \
        deps) \
            echo "Pushing nodeModules to Cachix..."; \
            nix build .#nodeModules -v; \
            cachix push {{ cache }} $(nix path-info .#nodeModules) ;; \
        *) echo "Usage: just cloud cache [darwin|nixos|deps]" ;; \
    esac

# ═══════════════════════════════════════════════════════════════════════════════
# REMOTE BUILDS (nixbuild.net)
# ═══════════════════════════════════════════════════════════════════════════════

# Build via nixbuild.net [darwin|nixos|test]
nixbuild TARGET="test":
    @case "{{ TARGET }}" in \
        test) \
            echo "Testing nixbuild.net connection..."; \
            ssh eu.nixbuild.net shell -- echo "Connected to nixbuild.net!" ;; \
        darwin) \
            echo "Building Darwin via nixbuild.net..."; \
            nix build .#darwinConfigurations.{{ darwin_host }}.system \
                --store ssh-ng://eu.nixbuild.net --eval-store auto --builders "" --no-link ;; \
        nixos) \
            echo "Building NixOS via nixbuild.net..."; \
            nix build .#nixosConfigurations.{{ host }}.config.system.build.toplevel \
                --store ssh-ng://eu.nixbuild.net --eval-store auto --builders "" --no-link ;; \
        *) echo "Usage: just cloud nixbuild [test|darwin|nixos]" ;; \
    esac

# ═══════════════════════════════════════════════════════════════════════════════
# PULUMI IaC (secrets injected via sops)
# ═══════════════════════════════════════════════════════════════════════════════

pulumi_dir := "cloud"
pulumi_stack := env_var_or_default("PULUMI_STACK", "prod")
root := `git rev-parse --show-toplevel`
secrets_file := root / "secrets/secrets.yaml"

# Helper: Run command with sops-injected secrets
[private]
_pulumi CMD:
    @sops exec-env {{ secrets_file }} 'export PULUMI_CONFIG_PASSPHRASE="$$pulumi_passphrase" && {{ CMD }}'

# Preview infrastructure changes
preview:
    @just cloud _pulumi "cd {{ root }}/{{ pulumi_dir }} && pulumi preview --stack {{ pulumi_stack }}"

# Deploy infrastructure changes
up:
    @just cloud _pulumi "cd {{ root }}/{{ pulumi_dir }} && pulumi up --stack {{ pulumi_stack }} --yes"

# Show current stack outputs
outputs:
    @just cloud _pulumi "cd {{ root }}/{{ pulumi_dir }} && pulumi stack output --stack {{ pulumi_stack }}"

# Refresh state from cloud provider
refresh:
    @just cloud _pulumi "cd {{ root }}/{{ pulumi_dir }} && pulumi refresh --stack {{ pulumi_stack }} --yes"

# Destroy infrastructure (DANGEROUS)
destroy:
    @echo "This will DESTROY all infrastructure in stack '{{ pulumi_stack }}'!"
    @read -p "Are you sure? (yes/no): " confirm; \
    if [ "$$confirm" = "yes" ]; then \
        just cloud _pulumi "cd {{ root }}/{{ pulumi_dir }} && pulumi destroy --stack {{ pulumi_stack }}"; \
    else echo "Aborted."; fi

# ═══════════════════════════════════════════════════════════════════════════════
# SECRETS MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

# Edit secrets (opens in $EDITOR)
secrets-edit:
    sops {{ secrets_file }}

# Show decrypted secrets (careful!)
secrets-show:
    @echo "WARNING: This will show decrypted secrets!"
    @read -p "Continue? (yes/no): " confirm; \
    if [ "$$confirm" = "yes" ]; then sops -d {{ secrets_file }}; fi

# Sync secrets to GitHub (one-time setup)
secrets-sync-github:
    @echo "Syncing secrets to GitHub..."
    @sops exec-env {{ secrets_file }} 'gh secret set PULUMI_CONFIG_PASSPHRASE --body "$$pulumi_passphrase"'
    @sops exec-env {{ secrets_file }} 'gh secret set TAILSCALE_AUTH --body "$$tailscale_auth"'
    @sops exec-env {{ secrets_file }} 'gh secret set ANTHROPIC_API_KEY --body "$$anthropic_api_key"'
    @sops exec-env {{ secrets_file }} 'gh secret set CACHIX_AUTH_TOKEN --body "$$cachix_auth_token"'
    @echo "Secrets synced to GitHub repository."

# ═══════════════════════════════════════════════════════════════════════════════
# DATA MIGRATION
# ═══════════════════════════════════════════════════════════════════════════════

# Sync data from R2 to GCS (one-time migration)
migrate-r2-to-gcs:
    @echo "Syncing health data from R2 to GCS..."
    @echo "Prerequisites: rclone configured with r2 and gcs remotes"
    rclone sync r2:health-analysis-data gs:hank-systems-data/health --progress
    @echo "Migration complete. Update DVC remote and test with 'dvc pull'."
