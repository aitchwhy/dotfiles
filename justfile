# Nix Darwin Configuration Manager
# Run 'just' to see available commands
set shell := ["bash", "-ec"]

# Auto-detect host
host := env_var_or_default("HOST", "hank-mbp-m4")

# Import namespaced modules
mod data "config/just/data.just"
mod nvim "config/just/nvim.just"
mod yazi "config/just/yazi.just"
mod agents "config/just/agents.just"

# Aliases
alias s := switch

# ═══════════════════════════════════════════════════════════════════════════════
# COMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

# List available commands
default:
    @just --list

# ═══════════════════════════════════════════════════════════════════════════════
# SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

# Rebuild and switch local system configuration
switch: _preflight _completions _fmt _lint _test
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Switching configuration..."
    sudo darwin-rebuild switch --flake .#{{ host }}
    # Auto-GC if > 10 generations (non-critical, don't fail on errors)
    gen_count=$(sudo darwin-rebuild --list-generations 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    if [ "$gen_count" -gt 10 ]; then
        echo ""
        echo "Auto-cleaning old generations ($gen_count > 10)..."
        sudo nix-collect-garbage --delete-older-than 7d || true
        nix store optimise || true
    fi
    echo ""
    echo "✓ System switched"

# Deploy everything: system + data sync
deploy: switch
    @echo ""
    @echo "Syncing data to GCS..."
    @just data push
    @echo ""
    @echo "✓ Full deployment complete"

# Validate configuration without applying
check: _preflight
    @echo "Running validation..."
    nix fmt -- --fail-on-change .
    nix flake check --no-build
    nix build .#darwinConfigurations.{{ host }}.system --no-link --print-out-paths > /dev/null
    @echo "✓ All checks passed"

# Rollback to previous generation
rollback:
    sudo darwin-rebuild switch --rollback

# ═══════════════════════════════════════════════════════════════════════════════
# DEVELOPMENT
# ═══════════════════════════════════════════════════════════════════════════════

# Enter development shell with pre-commit hooks
dev:
    nix develop -c $SHELL

# Update flake inputs
update:
    nix flake update

# ═══════════════════════════════════════════════════════════════════════════════
# GITHUB ACTIONS (Local)
# ═══════════════════════════════════════════════════════════════════════════════

# Read act arguments from config
act_args := shell("grep -v '^#' config/act/actrc | tr '\n' ' '")

# Run GitHub Actions locally (arguments passed to act)
# Usage: just gha -j job_name
gha *ARGS:
    act {{ act_args }} {{ ARGS }}

# List available GitHub Actions jobs
gha-list:
    @just gha -l

# Watch mode for rapid iteration on a specific job
# Usage: just gha-watch job_name
gha-watch JOB:
    @echo "Watching for changes to run {{ JOB }}..."
    @watchexec -e yml,yaml,ts,js,json,nix -- \
        just gha -j {{ JOB }}


# Show system status and health
status:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "═══════════════════════════════════════════════════════════════"
    echo "  System Status"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "Host:       {{ host }}"
    echo "Generation: $(darwin-rebuild --list-generations 2>/dev/null | tail -1 || echo 'N/A')"
    echo "Flake:      $(nix flake metadata --json 2>/dev/null | jq -r '.url' || echo 'git+file://.')"
    echo ""
    echo "Checks:"
    which nix > /dev/null && echo "  ✓ Nix" || echo "  ✗ Nix"
    which darwin-rebuild > /dev/null && echo "  ✓ darwin-rebuild" || echo "  ✗ darwin-rebuild"
    test -f flake.nix && echo "  ✓ flake.nix" || echo "  ✗ flake.nix"
    dirty=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    [ "$dirty" -eq 0 ] && echo "  ✓ Git clean" || echo "  ! Git dirty ($dirty files)"
    nix flake check --no-build > /dev/null 2>&1 && echo "  ✓ Flake valid" || echo "  ✗ Flake check failed"
    echo ""
    echo "Evolution:"
    bun run config/agents/evolution/evolve.ts --json 2>/dev/null | jq -r '"  Score: \(.score_percent)% | Trend: \(.trend) | Recommendation: \(.recommendation)"' 2>/dev/null || echo "  Run: just evolve"

# Evolution system dashboard
evolve *ARGS:
    @bun run config/agents/evolution/evolve.ts {{ ARGS }}

# Grade system health (TypeScript - Effect-based)
grade:
    @bun run config/agents/evolution/grade.ts

# Analyze trends and detect regressions
trends *ARGS:
    @bun run config/agents/evolution/trend-alert.ts {{ ARGS }}

# Synthesize lessons into CLAUDE.md update proposals
reflect:
    @bun run config/agents/evolution/reflect.ts

# ═══════════════════════════════════════════════════════════════════════════════
# CLAUDE CODE
# ═══════════════════════════════════════════════════════════════════════════════

# Check for Claude Code pattern updates
upgrade-check:
    @echo "Checking for Claude Code updates..."
    @echo ""
    @echo "1. Current settings.json hooks:"
    @jq -r '.hooks | keys[]' config/agents/settings.json 2>/dev/null || echo "   (unable to read)"
    @echo ""
    @echo "2. Current skills:"
    @ls -1 config/agents/skills/ 2>/dev/null | head -10 || echo "   (unable to list)"
    @echo ""
    @echo "See config/agents/skills/upgrade/SKILL.md for manual upgrade workflow."

# Show upgrade diff (placeholder)
upgrade-diff:
    @echo "Upgrade diff not yet implemented."
    @echo "Run: just upgrade-check"

# ═══════════════════════════════════════════════════════════════════════════════
# COPIER (Project Scaffolding)
# ═══════════════════════════════════════════════════════════════════════════════

# Regenerate versions.json from SSOT (run before copier copy)
build-copier-versions:
    @echo "Generating versions.json from SSOT..."
    @cd config/quality && tsx templates/copier-monorepo/scripts/build-versions.ts
    @echo "✓ versions.json updated"

# Create a new project from SSOT template
# Usage: just new-project my-app --data include_mobile=true
new-project NAME *ARGS:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Creating project: {{ NAME }}"
    just build-copier-versions
    pipx run copier copy ~/dotfiles/config/quality/templates/copier-monorepo ./{{ NAME }} \
        --data project_name={{ NAME }} \
        {{ ARGS }} \
        --trust
    echo ""
    echo "✓ Project created: {{ NAME }}"
    echo ""
    echo "Next steps:"
    echo "  cd {{ NAME }}"
    echo "  pnpm install"
    echo "  pnpm dev"

# ═══════════════════════════════════════════════════════════════════════════════
# HIDDEN HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

# Check for untracked nix/config files
[private]
_preflight:
    #!/usr/bin/env bash
    set -euo pipefail
    untracked=$(git ls-files --others --exclude-standard modules/ config/ | head -20)
    if [ -n "$untracked" ]; then
        echo "Error: Untracked files in modules/ or config/:"
        echo "$untracked" | sed 's/^/  /'
        echo ""
        echo "Flakes only see tracked files. Run: git add <files>"
        exit 1
    fi

[private]
_completions:
    #!/usr/bin/env bash
    set -euo pipefail
    cd config/completions
    [ -d node_modules ] || pnpm install --silent
    # Generate completions (quiet mode - only show summary)
    output=$(pnpm run generate 2>&1)
    generated=$(echo "$output" | grep -o 'Generated [0-9]* completion' | head -1 || echo "Generated 0 completion")
    echo "✓ Completions: $generated files"
    # Auto-stage generated completions if changed (Nix only sees tracked files)
    cd ../..
    if ! git diff --quiet config/completions/generated/ 2>/dev/null; then
        git add config/completions/generated/
        echo "  (auto-staged updated completions)"
    fi

[private]
_fmt:
    @nix fmt .

[private]
_lint:
    @nix flake check --no-build

[private]
_test:
    @nix build .#darwinConfigurations.{{ host }}.system --no-link --print-out-paths > /dev/null

[private]
_gc:
    sudo nix-collect-garbage --delete-older-than 7d
    nix store optimise

# ═══════════════════════════════════════════════════════════════════════════════
# TEST SUITES (hidden)
# ═══════════════════════════════════════════════════════════════════════════════

[private]
_test-ai:
    @bats tests/ai-cli.bats

[private]
_test-ai-static:
    @bats tests/ai-cli.bats --filter-tags '!live'

[private]
_test-rx:
    @bats tests/repomix.bats

[private]
_test-quality:
    cd config/brain && bun test

[private]
_verify-paragon:
    @./scripts/verify-paragon.sh

# ═══════════════════════════════════════════════════════════════════════════════
# NIX DEBUG (hidden)
# ═══════════════════════════════════════════════════════════════════════════════

[private]
_nix-check:
    @./scripts/verify-nix-optimization.sh

# ═══════════════════════════════════════════════════════════════════════════════
# PERFORMANCE (hidden)
# ═══════════════════════════════════════════════════════════════════════════════

[private]
_perf-report:
    @echo "PARAGON Guard Performance"
    @echo "========================="
    @if [ ! -f ~/.claude-metrics/perf.jsonl ]; then \
        echo "No metrics yet."; \
        exit 0; \
    fi
    @echo "Total: $$(wc -l < ~/.claude-metrics/perf.jsonl | tr -d ' ') checks"
    @echo "Blocked: $$(grep -c '"result":"block"' ~/.claude-metrics/perf.jsonl 2>/dev/null || echo 0)"
    @echo "Approved: $$(grep -c '"result":"approve"' ~/.claude-metrics/perf.jsonl 2>/dev/null || echo 0)"

[private]
_perf-clear:
    @rm -f ~/.claude-metrics/perf.jsonl
    @echo "Metrics cleared"

# ═══════════════════════════════════════════════════════════════════════════════
# VERSIONING (semver via git tags)
# ═══════════════════════════════════════════════════════════════════════════════

# Show current version from git tags
version:
    @git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0 (no tags)"

# Tag a new patch release (0.9.0 → 0.9.1)
release-patch:
    #!/usr/bin/env bash
    set -euo pipefail
    current=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0")
    IFS='.' read -r major minor patch <<< "$current"
    new="v${major}.${minor}.$((patch + 1))"
    echo "Releasing: v${current} → ${new}"
    git tag -a "$new" -m "Release ${new}"
    git push origin "$new"
    echo "✓ Tagged and pushed ${new}"

# Tag a new minor release (0.9.0 → 0.10.0)
release-minor:
    #!/usr/bin/env bash
    set -euo pipefail
    current=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0")
    IFS='.' read -r major minor patch <<< "$current"
    new="v${major}.$((minor + 1)).0"
    echo "Releasing: v${current} → ${new}"
    git tag -a "$new" -m "Release ${new}"
    git push origin "$new"
    echo "✓ Tagged and pushed ${new}"

# Tag a new major release (0.9.0 → 1.0.0)
release-major:
    #!/usr/bin/env bash
    set -euo pipefail
    current=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0")
    IFS='.' read -r major minor patch <<< "$current"
    new="v$((major + 1)).0.0"
    echo "Releasing: v${current} → ${new}"
    git tag -a "$new" -m "Release ${new}"
    git push origin "$new"
    echo "✓ Tagged and pushed ${new}"
