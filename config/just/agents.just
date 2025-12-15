# AI Agents Configuration Module
# Usage: just agents <command>
set shell := ["bash", "-uc"]

agents_dir := env_var("HOME") + "/dotfiles/config/agents"

# Show available agents commands
[private]
default:
    @just --list --justfile {{ source_file() }}

# NOTE: Global setup is handled by Nix (modules/home/apps/agents.nix)
# Run `just switch` from dotfiles root to configure

# Link AGENT.md as CLAUDE.md and GEMINI.md in current project
setup-project:
    ln -sf {{ agents_dir }}/AGENT.md ./CLAUDE.md
    ln -sf {{ agents_dir }}/AGENT.md ./GEMINI.md
    @echo "✓ Agent context linked"

# Remove agent context files from current project
clean-project:
    rm -f ./CLAUDE.md ./GEMINI.md
    @echo "✓ Agent context removed"

# Show symlink status for all agent configs
status:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Claude Code CLI ==="
    ls -la ~/.claude/settings.json 2>/dev/null || echo "  Not configured"
    ls -la ~/.claude/CLAUDE.md 2>/dev/null || echo "  No CLAUDE.md"
    echo ""
    echo "=== Gemini CLI ==="
    ls -la ~/.gemini/settings.json 2>/dev/null || echo "  Not configured"
    ls -la ~/.gemini/GEMINI.md 2>/dev/null || echo "  No GEMINI.md"
    echo ""
    echo "=== Antigravity ==="
    ls -la ~/.gemini/antigravity/mcp_config.json 2>/dev/null || echo "  Not configured"
    echo ""
    echo "=== Project ==="
    ls -la ./CLAUDE.md ./GEMINI.md 2>/dev/null || echo "  No context files"

# Validate all JSON config files
validate:
    @jq empty {{ agents_dir }}/settings/claude-code.json && echo "✓ claude-code.json"
    @jq empty {{ agents_dir }}/settings/gemini.json && echo "✓ gemini.json"
    @echo "✓ mcp-servers.json (managed by Nix - see ~/.config/claude/)"

# Open AGENT.md in editor
edit:
    ${EDITOR:-nvim} {{ agents_dir }}/AGENT.md

# Run evolution graders
grade:
    cd {{ agents_dir }}/evolution && bun run grade

# Show evolution metrics
metrics:
    cd {{ agents_dir }}/evolution && bun run metrics

# Run all 5 tiers of verification (hard gate)
verify PATH=".":
    sig verify {{ PATH }}

# Run verification with auto-fix
verify-fix PATH=".":
    sig verify --fix {{ PATH }}

# Show PARAGON cleanup statistics
paragon-stats:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "═══════════════════════════════════════════════════════════════"
    echo "  PARAGON Cleanup Statistics"
    echo "═══════════════════════════════════════════════════════════════"
    if [ ! -f ~/.claude-metrics/cleanup.jsonl ]; then
        echo "No metrics yet. Run 'just agents paragon-clean' to generate."
        exit 0
    fi
    echo ""
    echo "Total cleanups: $(wc -l < ~/.claude-metrics/cleanup.jsonl | tr -d ' ')"
    echo ""
    echo "Last 5 runs:"
    tail -5 ~/.claude-metrics/cleanup.jsonl | jq -r '"  \(.timestamp[:19]) | \(.mode) | \(.filesAnalyzed) files | \(.smellsDetected) smells"' 2>/dev/null || echo "  (parse error)"
    echo ""
    echo "Smells by severity (last run):"
    tail -1 ~/.claude-metrics/cleanup.jsonl | jq -r '.bySeverity | to_entries | .[] | "  \(.key): \(.value)"' 2>/dev/null || echo "  (no data)"

# Run full PARAGON cleanup on codebase
paragon-clean:
    @bun run {{ agents_dir }}/hooks/paragon-cleanup.ts --mode full
