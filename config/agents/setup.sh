#!/usr/bin/env bash
set -euo pipefail

AGENTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up unified agent configuration..."

# Claude Code CLI
mkdir -p ~/.claude
ln -sf "${AGENTS_DIR}/settings/claude-code.json" ~/.claude/settings.json
ln -sf "${AGENTS_DIR}/mcp-servers.json" ~/.claude/mcp-servers.json
ln -sf "${AGENTS_DIR}/AGENT.md" ~/.claude/CLAUDE.md
ln -sfn "${AGENTS_DIR}/commands" ~/.claude/commands
ln -sfn "${AGENTS_DIR}/agents" ~/.claude/agents
# Skills are individual symlinks (handled by Nix module)
echo "✓ Claude Code CLI configured"

# Gemini CLI
mkdir -p ~/.gemini
ln -sf "${AGENTS_DIR}/settings/gemini.json" ~/.gemini/settings.json
ln -sf "${AGENTS_DIR}/AGENT.md" ~/.gemini/GEMINI.md
ln -sf "${AGENTS_DIR}/mcp-servers.json" ~/.gemini/mcp-servers.json
echo "✓ Gemini CLI configured"

# Antigravity IDE
mkdir -p ~/.gemini/antigravity
ln -sf "${AGENTS_DIR}/mcp-servers.json" ~/.gemini/antigravity/mcp_config.json
echo "✓ Antigravity IDE configured"

echo ""
echo "Done! Run 'just setup-project' in any project directory to add context files."
