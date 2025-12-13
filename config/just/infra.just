# Infrastructure as Code Module (Pulumi TypeScript)
# Usage: just infra <command>
set shell := ["bash", "-uc"]

# Pulumi stack name
stack := env_var_or_default("PULUMI_STACK", "dev")
project_dir := "infra"

# Show available infra commands
[private]
default:
    @just --list --justfile {{ source_file() }}

# ═══════════════════════════════════════════════════════════════════════════════
# PULUMI OPERATIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Initialize Pulumi project (first-time setup)
init:
    @if [ ! -d "{{ project_dir }}" ]; then \
        echo "Creating Pulumi project in {{ project_dir }}/..."; \
        mkdir -p {{ project_dir }}; \
        cd {{ project_dir }} && pulumi new typescript --name dotfiles-infra --stack {{ stack }} --yes; \
    else \
        echo "{{ project_dir }}/ already exists. Run 'just infra login' to configure."; \
    fi

# Login to Pulumi backend
login:
    cd {{ project_dir }} && pulumi login

# Preview infrastructure changes
preview:
    cd {{ project_dir }} && pulumi preview --stack {{ stack }}

# Deploy infrastructure changes
up:
    cd {{ project_dir }} && pulumi up --stack {{ stack }}

# Destroy infrastructure (DANGEROUS)
destroy:
    @echo "This will DESTROY all infrastructure in stack '{{ stack }}'!"
    @read -p "Are you sure? (yes/no): " confirm; \
    if [ "$$confirm" = "yes" ]; then \
        cd {{ project_dir }} && pulumi destroy --stack {{ stack }}; \
    else echo "Aborted."; fi

# Show current stack outputs
outputs:
    cd {{ project_dir }} && pulumi stack output --stack {{ stack }}

# Show stack history
history:
    cd {{ project_dir }} && pulumi stack history --stack {{ stack }}

# Refresh state from cloud provider
refresh:
    cd {{ project_dir }} && pulumi refresh --stack {{ stack }}

# ═══════════════════════════════════════════════════════════════════════════════
# STACK MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

# List all stacks
stacks:
    cd {{ project_dir }} && pulumi stack ls

# Select a different stack
select STACK:
    cd {{ project_dir }} && pulumi stack select {{ STACK }}

# Create a new stack
new-stack NAME:
    cd {{ project_dir }} && pulumi stack init {{ NAME }}

# ═══════════════════════════════════════════════════════════════════════════════
# LEGACY MIGRATION (OpenTofu/Terranix)
# ═══════════════════════════════════════════════════════════════════════════════

# Import existing Terraform state to Pulumi (migration helper)
import-tf:
    @echo "To import existing Terraform resources:"
    @echo "1. cd {{ project_dir }}"
    @echo "2. pulumi import <type> <name> <id>"
    @echo ""
    @echo "Example: pulumi import gcp:compute:Instance my-vm projects/my-project/zones/us-central1-a/instances/my-vm"
