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
    nix flake check

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

# Development shell
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
# SELF-EVOLUTION
# ═══════════════════════════════════════════════════════════════════════════════

# Full evolution cycle (grade + reflect)
evolve *ARGS:
    @bash config/claude-code/evolution/evolve.sh {{ ARGS }}

# Quick status dashboard
evolve-status:
    @bash config/claude-code/evolution/evolve.sh status

# Initialize evolution system
evolve-init:
    @mkdir -p .claude-metrics config/claude-code/evolution/lessons
    @chmod +x config/claude-code/evolution/*.sh config/claude-code/evolution/**/*.sh 2>/dev/null || true
    @echo "✓ Evolution system initialized"