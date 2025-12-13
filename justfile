# Nix Darwin Configuration Manager
# 8 top-level commands. Run 'just' to see status and available commands.
set shell := ["bash", "-uc"]

# Auto-detect host
host := env_var_or_default("HOST", "hank-mbp-m4")

# Import namespaced modules
mod cloud "config/just/cloud.just"

# ═══════════════════════════════════════════════════════════════════════════════
# TOP-LEVEL COMMANDS (8)
# ═══════════════════════════════════════════════════════════════════════════════

# Show system status and available commands
default:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "═══════════════════════════════════════════════════════════════"
    gen=$(darwin-rebuild --list-generations 2>/dev/null | tail -1 | awk '{print $1}' || echo '?')
    health=$(bash config/agents/evolution/evolve.sh --json 2>/dev/null | jq -r '.score_percent // empty' 2>/dev/null || true)
    printf "  Darwin: {{ host }} | Gen: %s" "$gen"
    if [ -n "$health" ]; then printf " | Health: %s%%" "$health"; fi
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "Commands:"
    echo "  just sync     (s)  Local: fmt → lint → test → switch → gc"
    echo "  just full     (f)  Full: sync + cloud + data (the everything command)"
    echo "  just check    (c)  Quick validation without switching"
    echo "  just dev      (d)  Development shell with pre-commit"
    echo "  just info     (i)  System status and health"
    echo "  just update   (u)  Update flake inputs"
    echo "  just rollback      Rollback to previous generation"
    echo "  just evolve        Evolution system dashboard"
    echo ""
    echo "Modules:"
    echo "  just cloud <cmd>   Cloud ops: ssh, colmena, pulumi, cache"

# The one command: fmt → lint → test → switch → auto-gc [alias: s]
sync: _preflight _fmt _lint _test
    @echo "Switching configuration..."
    sudo darwin-rebuild switch --flake .#{{ host }}
    @# Auto-GC if > 10 generations
    @gen_count=$$(darwin-rebuild --list-generations 2>/dev/null | wc -l | tr -d ' '); \
    if [ "$$gen_count" -gt 10 ]; then \
        echo ""; \
        echo "Auto-cleaning old generations ($$gen_count > 10)..."; \
        sudo nix-collect-garbage --delete-older-than 7d; \
        nix store optimise; \
    fi
    @echo ""
    @echo "✓ System synchronized"

alias s := sync

# Full sync: local + cloud + data [alias: f]
full: sync _sync-cloud _sync-data
    @echo ""
    @echo "✓ Full sync complete (darwin + cloud + data)"

alias f := full

# Quick validation without switching [alias: c]
check: _preflight
    @echo "Running validation..."
    nix fmt -- --check
    nix flake check --no-build
    nix build .#darwinConfigurations.{{ host }}.system --no-link --print-out-paths > /dev/null
    @echo "✓ All checks passed"

alias c := check

# Development shell with pre-commit hooks [alias: d]
dev:
    nix develop -c $SHELL

alias d := dev

# System status and health [alias: i]
info:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "═══════════════════════════════════════════════════════════════"
    echo "  System Information"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "Host:       {{ host }}"
    echo "Generation: $(darwin-rebuild --list-generations 2>/dev/null | tail -1 || echo 'N/A')"
    echo "Flake:      $(nix flake metadata --json 2>/dev/null | jq -r '.url' || echo 'git+file://.')"
    echo ""
    echo "Health Checks:"
    which nix > /dev/null && echo "  ✓ Nix" || echo "  ✗ Nix"
    which darwin-rebuild > /dev/null && echo "  ✓ darwin-rebuild" || echo "  ✗ darwin-rebuild"
    test -f flake.nix && echo "  ✓ flake.nix" || echo "  ✗ flake.nix"
    dirty=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    [ "$dirty" -eq 0 ] && echo "  ✓ Git clean" || echo "  ! Git dirty ($dirty files)"
    untracked=$(git ls-files --others --exclude-standard modules/ config/ 2>/dev/null | wc -l | tr -d ' ')
    [ "$untracked" -eq 0 ] && echo "  ✓ No untracked modules/config" || echo "  ! Untracked files ($untracked)"
    nix flake check --no-build > /dev/null 2>&1 && echo "  ✓ Flake valid" || echo "  ✗ Flake check failed"
    echo ""
    echo "Evolution:"
    bash config/agents/evolution/evolve.sh --json 2>/dev/null | jq -r '"  Score: \(.score_percent)% | Trend: \(.trend) | Recommendation: \(.recommendation)"' 2>/dev/null || echo "  Run: just evolve"

alias i := info

# Update flake inputs [alias: u]
update:
    nix flake update

alias u := update

# Rollback to previous generation
rollback:
    sudo darwin-rebuild switch --rollback

# Evolution system dashboard
evolve *ARGS:
    @bash config/agents/evolution/evolve.sh {{ ARGS }}

# ═══════════════════════════════════════════════════════════════════════════════
# HIDDEN HELPERS (prefixed with _ to hide from default listing)
# ═══════════════════════════════════════════════════════════════════════════════

# Sync secrets and deploy cloud infrastructure
[private]
_sync-cloud:
    @echo ""
    @echo "Syncing cloud infrastructure..."
    @just cloud secrets-sync-github
    @just cloud up

# Sync DVC data to GCS
[private]
_sync-data:
    @echo ""
    @echo "Syncing data to GCS..."
    @cd domains/health && uv run dvc push

# Check for untracked nix/config files (flakes won't see them)
[private]
_preflight:
    @untracked=$$(git ls-files --others --exclude-standard modules/ config/ | head -20); \
    if [ -n "$$untracked" ]; then \
        echo "Error: Untracked files in modules/ or config/:"; \
        echo "$$untracked" | sed 's/^/  /'; \
        echo ""; \
        echo "Flakes only see tracked files. Run: git add <files>"; \
        exit 1; \
    fi

# Format all nix files
[private]
_fmt:
    @nix fmt

# Lint check (format + flake)
[private]
_lint:
    @nix fmt -- --check
    @nix flake check --no-build

# Build test
[private]
_test:
    @nix build .#darwinConfigurations.{{ host }}.system --no-link --print-out-paths > /dev/null

# Run pre-commit on all files
[private]
_lint-all:
    nix develop -c pre-commit run --all-files

# Run pre-commit on staged files only
[private]
_lint-staged:
    nix develop -c pre-commit run

# Build without switching
[private]
_build: _preflight
    darwin-rebuild build --flake .#{{ host }}

# Preview changes before applying
[private]
_diff:
    darwin-rebuild build --flake .#{{ host }} && \
    nix store diff-closures /run/current-system ./result

# Manual garbage collection
[private]
_gc:
    sudo nix-collect-garbage --delete-older-than 7d
    nix store optimise

# NeoVim startup health check
[private]
_nvim-test:
    @bash tests/nvim-health.sh

# ═══════════════════════════════════════════════════════════════════════════════
# TEST SUITES (hidden - use directly when needed)
# ═══════════════════════════════════════════════════════════════════════════════

# AI CLI smoke tests
[private]
_test-ai:
    @bats tests/ai-cli.bats

# AI CLI static tests (no API calls)
[private]
_test-ai-static:
    @bats tests/ai-cli.bats --filter-tags '!live'

# Repomix tests
[private]
_test-rx:
    @bats tests/repomix.bats

# Signet tests
[private]
_test-signet:
    cd config/signet && bun test

# Factory smoke tests
[private]
_test-factory:
    cd config/signet && bun test tests/e2e/factory-smoke.test.ts

# Verify factory health
[private]
_verify-factory:
    @bash scripts/verify-factory.sh

# PARAGON compliance verification
[private]
_verify-paragon:
    @./scripts/verify-paragon.sh

# ═══════════════════════════════════════════════════════════════════════════════
# NIX DEBUG UTILITIES (hidden - use directly when needed)
# ═══════════════════════════════════════════════════════════════════════════════

# Verify Nix build optimization patterns
[private]
_nix-check:
    @./scripts/verify-nix-optimization.sh

# Benchmark Nix build times
[private]
_nix-bench:
    @echo "Cold build (first run)..."
    rm -rf result
    time nix build .#api 2>&1 | tail -5
    @echo ""
    @echo "Warm build (source change only)..."
    touch apps/api/src/index.ts 2>/dev/null || touch src/index.ts 2>/dev/null || true
    time nix build .#api 2>&1 | tail -5

# Show Nix closure sizes
[private]
_nix-sizes:
    @echo "Closure sizes (largest first):"
    nix path-info -rsSh .#api 2>/dev/null | sort -k2 -h | tail -15 || echo "Build .#api first"

# ═══════════════════════════════════════════════════════════════════════════════
# PERFORMANCE METRICS (hidden - use directly when needed)
# ═══════════════════════════════════════════════════════════════════════════════

# Show hook performance report
[private]
_perf-report:
    @echo "PARAGON Guard Performance Report"
    @echo "================================="
    @if [ ! -f ~/.claude-metrics/perf.jsonl ]; then \
        echo "No metrics yet. Run some Claude Code sessions first."; \
        exit 0; \
    fi
    @echo ""
    @echo "Total checks: $$(wc -l < ~/.claude-metrics/perf.jsonl | tr -d ' ')"
    @echo ""
    @echo "Average latency by tool:"
    @cat ~/.claude-metrics/perf.jsonl | jq -s 'group_by(.tool) | map({tool: .[0].tool, count: length, avg_ms: ([.[].duration_ms] | add / length | . * 100 | round / 100)}) | sort_by(.count) | reverse | .[]' 2>/dev/null || echo "  (jq required)"
    @echo ""
    @echo "Block rate:"
    @echo "  Blocked: $$(grep -c '"result":"block"' ~/.claude-metrics/perf.jsonl 2>/dev/null || echo 0)"
    @echo "  Approved: $$(grep -c '"result":"approve"' ~/.claude-metrics/perf.jsonl 2>/dev/null || echo 0)"

# Clear performance metrics
[private]
_perf-clear:
    @rm -f ~/.claude-metrics/perf.jsonl
    @echo "Performance metrics cleared"

# Show recent performance (last 50)
[private]
_perf-recent:
    @tail -50 ~/.claude-metrics/perf.jsonl 2>/dev/null | jq '.' 2>/dev/null || echo "No recent metrics"
