# Quick commands for Nix Darwin - Run 'just' to see all
set shell := ["bash", "-uc"]

# Auto-detect host or use default
host := env_var_or_default("HOST", "hank-mbp-m4")

# Show available commands
default:
    @just --list

# Check for untracked nix/config files (flakes won't see them)
preflight:
    @untracked=$(git ls-files --others --exclude-standard modules/ config/ | head -20); \
    if [ -n "$untracked" ]; then \
        echo "Error: Untracked files in modules/ or config/:"; \
        echo "$untracked" | sed 's/^/  /'; \
        echo ""; \
        echo "Flakes only see tracked files. Run: git add <files>"; \
        exit 1; \
    fi

# Switch configuration (rebuild + activate) [alias: s]
switch: preflight
    sudo darwin-rebuild switch --flake .#{{host}}

alias s := switch

# Build without switching [alias: b]
build: preflight
    darwin-rebuild build --flake .#{{host}}

alias b := build

# Run all checks
check: lint test
    @echo "✓ All checks passed"

# Lint and format check
lint:
    nix fmt -- --check
    nix flake check --no-build

# Run pre-commit hooks on all files
lint-all:
    nix develop -c pre-commit run --all-files

# Run pre-commit hooks on staged files only
lint-staged:
    nix develop -c pre-commit run

# Test the build
test:
    nix build .#darwinConfigurations.{{host}}.system --no-link --print-out-paths

# Format all nix files
fmt:
    nix fmt

# Update flake inputs [alias: u]
update:
    nix flake update

alias u := update

# Garbage collect (keep 7 days) [alias: gc]
clean:
    sudo nix-collect-garbage --delete-older-than 7d
    nix store optimise

alias gc := clean

# Show system info [alias: i]
info:
    @echo "Host: {{host}}"
    @echo "Generation:"
    @darwin-rebuild --list-generations 2>/dev/null | tail -n 1 || echo "  (no access to system profile)"
    @echo "Flake:"
    @nix flake metadata --json | jq -r '.url' 2>/dev/null || echo "  git+file://$(pwd)"

alias i := info

# Development shell (with pre-commit hooks)
dev:
    nix develop -c $SHELL

# Quick health check
doctor:
    @echo "System Health Check:"
    @echo "==================="
    @which nix > /dev/null && echo "✓ Nix installed" || echo "✗ Nix not found"
    @which darwin-rebuild > /dev/null && echo "✓ Darwin-rebuild installed" || echo "✗ Darwin-rebuild not found"
    @test -f flake.nix && echo "✓ Flake found" || echo "✗ No flake.nix"
    @git status --porcelain | wc -l | xargs -I {} test {} -eq 0 && echo "✓ Git clean" || echo "! Git dirty"
    @git ls-files --others --exclude-standard modules/ config/ | wc -l | xargs -I {} test {} -eq 0 && echo "✓ No untracked modules/config" || echo "! Untracked files in modules/ or config/"
    @nix flake check --no-build > /dev/null 2>&1 && echo "✓ Flake valid" || echo "✗ Flake check failed"
    @darwin-rebuild --list-generations 2>/dev/null | tail -n 1 | grep -q . && echo "✓ System generations accessible" || echo "! No system profile access"

# NeoVim startup health check (no Lua errors)
nvim-test:
    @bash tests/nvim-health.sh

# AI CLI smoke tests (tests Claude config and knowledge)
test-ai:
    @echo "Running AI CLI smoke tests..."
    @bats tests/ai-cli.bats

# AI CLI smoke tests (static only, no API calls)
test-ai-static:
    @echo "Running static AI CLI tests only..."
    @bats tests/ai-cli.bats --filter-tags '!live'

# Repomix configuration tests
test-rx:
    @echo "Running Repomix tests..."
    @bats tests/repomix.bats

# Full validation pipeline (format check + flake check + build test)
validate: lint test
    @echo "✓ All validation passed"

# PARAGON compliance verification (14 guards)
verify-paragon:
    @./scripts/verify-paragon.sh

# Alias for PARAGON verification
paragon: verify-paragon

# Quick rebuild with validation
rebuild: fmt check switch
    @echo "✓ Configuration rebuilt successfully"

# Preview changes before applying
diff:
    darwin-rebuild build --flake .#{{host}} && \
    nix store diff-closures /run/current-system ./result

# Rollback to previous generation
rollback:
    sudo darwin-rebuild switch --rollback

# ═══════════════════════════════════════════════════════════════════════════════
# CLOUD (NixOS Remote Deployment)
# ═══════════════════════════════════════════════════════════════════════════════

# Cloud host for deployment
cloud_host := env_var_or_default("CLOUD_HOST", "cloud")

# Build cloud configuration locally
cloud-build:
    nix build .#nixosConfigurations.{{cloud_host}}.config.system.build.toplevel --no-link --print-out-paths

# Deploy NixOS to a new server (initial install)
cloud-deploy IP:
    @echo "Deploying NixOS to {{IP}}..."
    @echo "This will ERASE ALL DATA on the target server!"
    @read -p "Are you sure? (yes/no): " confirm; \
    if [ "$$confirm" = "yes" ]; then \
        nix run github:nix-community/nixos-anywhere -- \
            --flake .#{{cloud_host}} \
            --build-on-remote \
            root@{{IP}}; \
    else \
        echo "Aborted."; \
    fi

# Update existing cloud server
cloud-update:
    @echo "Updating {{cloud_host}} via SSH..."
    ssh {{cloud_host}} "cd /etc/nixos && sudo nixos-rebuild switch --flake .#{{cloud_host}}"

# SSH to cloud server
cloud-ssh:
    ssh {{cloud_host}}

# SSH with mosh (resilient connection)
cloud-mosh:
    mosh {{cloud_host}}

# Attach to Zellij session on cloud
cloud-attach:
    ssh -t {{cloud_host}} "zellij attach dev || zellij -s dev"

# Show cloud server status
cloud-status:
    @ssh {{cloud_host}} "echo '=== System ===' && uname -a && echo && \
        echo '=== Uptime ===' && uptime && echo && \
        echo '=== Memory ===' && free -h && echo && \
        echo '=== Disk ===' && df -h / && echo && \
        echo '=== Tailscale ===' && tailscale status || true"

# ═══════════════════════════════════════════════════════════════════════════════
# COLMENA (Parallel NixOS Deployment)
# ═══════════════════════════════════════════════════════════════════════════════

# Deploy cloud with Colmena (requires Tailscale connection)
cloud-colmena:
    nix run nixpkgs#colmena -- apply --on {{cloud_host}} --evaluator streaming

# Evaluate Colmena config (dry-run, no deployment)
cloud-colmena-eval:
    nix run nixpkgs#colmena -- eval

# Deploy all hosts with Colmena
cloud-colmena-all:
    nix run nixpkgs#colmena -- apply --evaluator streaming

# Show Colmena deployment plan
cloud-colmena-plan:
    nix run nixpkgs#colmena -- build --on {{cloud_host}}

# ═══════════════════════════════════════════════════════════════════════════════
# NIXBUILD.NET (Remote Builds)
# ═══════════════════════════════════════════════════════════════════════════════

# Test nixbuild.net connectivity
nixbuild-test:
    @echo "Testing nixbuild.net connection..."
    @ssh eu.nixbuild.net shell -- echo "Connected to nixbuild.net!"

# Build Darwin config via nixbuild.net remote store
nixbuild-darwin:
    @echo "Building Darwin config via nixbuild.net..."
    nix build .#darwinConfigurations.{{host}}.system \
        --store ssh-ng://eu.nixbuild.net \
        --eval-store auto \
        --builders "" \
        --no-link

# Build NixOS config via nixbuild.net remote store
nixbuild-nixos:
    @echo "Building NixOS config via nixbuild.net..."
    nix build .#nixosConfigurations.{{cloud_host}}.config.system.build.toplevel \
        --store ssh-ng://eu.nixbuild.net \
        --eval-store auto \
        --builders "" \
        --no-link

# ═══════════════════════════════════════════════════════════════════════════════
# CACHIX (Binary Cache)
# ═══════════════════════════════════════════════════════════════════════════════

# Push Darwin build to Cachix
cache-push-darwin:
    @echo "Building and pushing Darwin to Cachix..."
    nix build .#darwinConfigurations.{{host}}.system -o darwin-result
    cachix push hank-dotfiles darwin-result
    rm darwin-result

# Push NixOS build to Cachix
cache-push-nixos:
    @echo "Building and pushing NixOS to Cachix..."
    nix build .#nixosConfigurations.{{cloud_host}}.config.system.build.toplevel -o nixos-result
    cachix push hank-dotfiles nixos-result
    rm nixos-result

# ═══════════════════════════════════════════════════════════════════════════════
# SELF-EVOLUTION
# ═══════════════════════════════════════════════════════════════════════════════

# Full evolution cycle (grade + reflect)
evolve *ARGS:
    @bash config/agents/evolution/evolve.sh {{ ARGS }}

# Quick status dashboard
evolve-status:
    @bash config/agents/evolution/evolve.sh status

# Initialize evolution system
evolve-init:
    @mkdir -p .claude-metrics config/agents/evolution/lessons
    @chmod +x config/agents/evolution/*.sh config/agents/evolution/**/*.sh 2>/dev/null || true
    @echo "✓ Evolution system initialized"

# Trend analysis and alerting
evolve-trends:
    @bash config/agents/evolution/trend-alert.sh analyze

# Check for degradation patterns
evolve-degradation:
    @bash config/agents/evolution/trend-alert.sh degradation

# Show recent alerts
evolve-alerts:
    @bash config/agents/evolution/trend-alert.sh alerts

# Generate weekly report
evolve-report:
    @bash config/agents/evolution/weekly-report.sh generate

# View latest weekly report
evolve-report-view:
    @bash config/agents/evolution/weekly-report.sh view

# List all weekly reports
evolve-report-list:
    @bash config/agents/evolution/weekly-report.sh list

# ═══════════════════════════════════════════════════════════════════════════════
# REPOMIX (Codebase Snapshots) - Delegates to ~/.local/bin/rx
# ═══════════════════════════════════════════════════════════════════════════════

# Repomix CLI - show help or run subcommand
rx *ARGS:
    @~/.local/bin/rx {{ ARGS }}

# Aliases for common operations
rx-copy *ARGS:
    @~/.local/bin/rx copy {{ ARGS }}

rx-dots *ARGS:
    @~/.local/bin/rx dots {{ ARGS }}

rx-ember *ARGS:
    @~/.local/bin/rx ember {{ ARGS }}

rx-remote REPO *ARGS:
    @~/.local/bin/rx remote {{ REPO }} {{ ARGS }}

rx-config:
    @~/.local/bin/rx config

# Concern-specific context generation (Universal Project Factory)
rx-nix:
    @repomix -c config/repomix/nix.json

rx-signet:
    @repomix -c config/repomix/signet.json

rx-agents:
    @repomix -c config/repomix/agents.json

# ═══════════════════════════════════════════════════════════════════════════════
# UNIVERSAL PROJECT FACTORY
# ═══════════════════════════════════════════════════════════════════════════════

# Verify factory health
verify-factory:
    @bash scripts/verify-factory.sh

# ═══════════════════════════════════════════════════════════════════════════════
# SIGNET (Code Quality & Generation Platform)
# ═══════════════════════════════════════════════════════════════════════════════

# Signet CLI - run any command
sig *ARGS:
    @signet {{ ARGS }}

# Validate project structure against spec
sig-validate PATH=".":
    @signet validate {{ PATH }}

# Check version alignment against SSOT (versions.json)
sig-doctor:
    @cd config/signet && bun run src/doctor.ts

# Auto-fix architecture drift
sig-comply PATH=".":
    @signet comply {{ PATH }}

# Initialize new project (types: monorepo, api, ui, library, infra)
sig-init TYPE NAME:
    @signet init {{ TYPE }} {{ NAME }}

# Generate workspace in existing project
sig-gen TYPE NAME:
    @signet gen {{ TYPE }} {{ NAME }}

# Migrate project to STACK compliance
sig-migrate PATH="." *ARGS:
    @signet migrate {{ PATH }} {{ ARGS }}

# Run 5-tier verification
sig-verify PATH="." *ARGS:
    @signet verify {{ PATH }} {{ ARGS }}

# Run signet tests (unit + integration)
test-signet:
    @echo "Running signet tests..."
    cd config/signet && bun test

# Run factory smoke tests (validates signet init output)
test-factory:
    @echo "Running factory smoke tests..."
    cd config/signet && bun test tests/e2e/factory-smoke.test.ts

# ═══════════════════════════════════════════════════════════════════════════════
# INFRASTRUCTURE (Terranix + OpenTofu)
# ═══════════════════════════════════════════════════════════════════════════════

# Generate Terraform JSON from Terranix (Nix -> Terraform)
tf-gen:
    @echo "Generating Terraform config from Nix..."
    nix build .#terraform-config
    @mkdir -p infra
    cp result/config.tf.json infra/
    @echo "Generated infra/config.tf.json"

# Terraform/OpenTofu plan
tf-plan: tf-gen
    cd infra && tofu plan

# Terraform/OpenTofu apply
tf-apply: tf-gen
    cd infra && tofu apply

# Terraform/OpenTofu init
tf-init:
    cd infra && tofu init

# Terraform/OpenTofu destroy (use with caution)
tf-destroy:
    cd infra && tofu destroy

# ═══════════════════════════════════════════════════════════════════════════════
# CONTEXT GENERATION
# ═══════════════════════════════════════════════════════════════════════════════

# Show editor context status (now using bootloader symlinks)
gen-context:
    @echo "Editor context is now managed via symlinks (bootloader architecture)"
    @echo ".cursorrules -> config/agents/AGENTS.md"
    @ls -la .cursorrules 2>/dev/null || echo ".cursorrules symlink not found"

# ═══════════════════════════════════════════════════════════════════════════════
# NIX BUILD OPTIMIZATION
# ═══════════════════════════════════════════════════════════════════════════════

# Verify Nix build follows optimization patterns
nix-check:
    @./scripts/verify-nix-optimization.sh

# Push nodeModules to Cachix (run after lockfile changes)
nix-cache-deps cache="hank-dotfiles":
    @echo "Pushing nodeModules to Cachix..."
    nix build .#nodeModules -v
    cachix push {{cache}} $(nix path-info .#nodeModules)
    @echo "nodeModules cached"

# Benchmark Nix build times
nix-bench:
    @echo "Cold build (first run)..."
    rm -rf result
    time nix build .#api 2>&1 | tail -5
    @echo ""
    @echo "Warm build (source change only)..."
    touch apps/api/src/index.ts 2>/dev/null || touch src/index.ts 2>/dev/null || true
    time nix build .#api 2>&1 | tail -5

# Show Nix closure sizes
nix-sizes:
    @echo "Closure sizes (largest first):"
    nix path-info -rsSh .#api 2>/dev/null | sort -k2 -h | tail -15 || echo "Build .#api first"

# ═══════════════════════════════════════════════════════════════════════════════
# PERFORMANCE METRICS
# ═══════════════════════════════════════════════════════════════════════════════

# Show hook performance report
perf-report:
    @echo "PARAGON Guard Performance Report"
    @echo "================================="
    @if [ ! -f ~/.claude-metrics/perf.jsonl ]; then \
        echo "No metrics yet. Run some Claude Code sessions first."; \
        exit 0; \
    fi
    @echo ""
    @echo "Total checks: $(wc -l < ~/.claude-metrics/perf.jsonl | tr -d ' ')"
    @echo ""
    @echo "Average latency by tool:"
    @cat ~/.claude-metrics/perf.jsonl | jq -s 'group_by(.tool) | map({tool: .[0].tool, count: length, avg_ms: ([.[].duration_ms] | add / length | . * 100 | round / 100)}) | sort_by(.count) | reverse | .[]' 2>/dev/null || echo "  (jq required for detailed analysis)"
    @echo ""
    @echo "Block rate:"
    @echo "  Blocked: $(grep -c '"result":"block"' ~/.claude-metrics/perf.jsonl 2>/dev/null || echo 0)"
    @echo "  Approved: $(grep -c '"result":"approve"' ~/.claude-metrics/perf.jsonl 2>/dev/null || echo 0)"
    @echo ""
    @echo "Slowest checks (>50ms):"
    @cat ~/.claude-metrics/perf.jsonl | jq -s '[.[] | select(.duration_ms > 50)] | sort_by(.duration_ms) | reverse | .[:10] | .[] | "\(.duration_ms)ms - \(.tool) - \(.file[:40])"' -r 2>/dev/null || echo "  (jq required)"

# Clear performance metrics
perf-clear:
    @rm -f ~/.claude-metrics/perf.jsonl
    @echo "Performance metrics cleared"

# Show recent performance (last 50)
perf-recent:
    @tail -50 ~/.claude-metrics/perf.jsonl 2>/dev/null | jq '.' 2>/dev/null || echo "No recent metrics or jq not available"