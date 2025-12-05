# Claude Code CLI configuration
# Manages ~/.claude/ directory with CLAUDE.md, settings, commands, agents, skills
# Note: This is SEPARATE from claude.nix which manages Claude Desktop
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.modules.home.apps.claudeCode = {
    enable = mkEnableOption "Claude Code CLI configuration";
  };

  config = mkIf config.modules.home.apps.claudeCode.enable {
    # jq required for JSON merging
    home.packages = [pkgs.jq];

    # Static configs (immutable - symlinked)
    home.file = {
      # Core config
      ".claude/CLAUDE.md".source = ../../../config/claude-code/CLAUDE.md;

      # Commands and agents
      ".claude/commands".source = ../../../config/claude-code/commands;
      ".claude/agents".source = ../../../config/claude-code/agents;

      # Skills - project-specific patterns
      ".claude/skills/ember-patterns".source = ../../../config/claude-code/skills/ember-patterns;
      ".claude/skills/hono-workers".source = ../../../config/claude-code/skills/hono-workers;
      ".claude/skills/tanstack-patterns".source = ../../../config/claude-code/skills/tanstack-patterns;
      ".claude/skills/livekit-agents".source = ../../../config/claude-code/skills/livekit-agents;

      # Skills - general TypeScript/engineering patterns
      ".claude/skills/typescript-patterns".source = ../../../config/claude-code/skills/typescript-patterns;
      ".claude/skills/zod-patterns".source = ../../../config/claude-code/skills/zod-patterns;
      ".claude/skills/result-patterns".source = ../../../config/claude-code/skills/result-patterns;
      ".claude/skills/tdd-patterns".source = ../../../config/claude-code/skills/tdd-patterns;
      ".claude/skills/nix-darwin-patterns".source = ../../../config/claude-code/skills/nix-darwin-patterns;
    };

    # Mutable configs (merge/copy-on-init pattern)
    home.activation.claudeCodeConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      CLAUDE_DIR="$HOME/.claude"
      SETTINGS_FILE="$CLAUDE_DIR/settings.json"
      MCP_FILE="$HOME/.claude.json"
      SOURCE_SETTINGS="${../../../config/claude-code/settings.json}"
      SOURCE_MCP="${../../../config/claude-code/mcp-servers.json}"

      $DRY_RUN_CMD mkdir -p "$CLAUDE_DIR"
      $DRY_RUN_CMD mkdir -p "$CLAUDE_DIR/skills"

      # ========================================
      # settings.json - merge hooks into existing
      # ========================================
      if [ -L "$SETTINGS_FILE" ]; then
        $DRY_RUN_CMD rm "$SETTINGS_FILE"
        echo "Removed old Claude Code settings symlink"
      fi

      if [ ! -f "$SETTINGS_FILE" ]; then
        # Fresh install - copy source
        $DRY_RUN_CMD cp "$SOURCE_SETTINGS" "$SETTINGS_FILE"
        $DRY_RUN_CMD chmod 644 "$SETTINGS_FILE"
        echo "Claude Code settings.json initialized"
      else
        # Existing file - merge hooks and permissions, preserve statusLine
        MERGED=$(${pkgs.jq}/bin/jq -s '
          .[0] as $existing | .[1] as $source |
          $existing * {
            permissions: ($existing.permissions // {}) * $source.permissions,
            hooks: ($existing.hooks // {}) * $source.hooks
          }
        ' "$SETTINGS_FILE" "$SOURCE_SETTINGS")
        if [ -n "$MERGED" ]; then
          echo "$MERGED" > "$SETTINGS_FILE"
          echo "Claude Code settings.json merged (hooks + permissions added)"
        fi
      fi

      # ========================================
      # ~/.claude.json - merge MCP servers
      # ========================================
      if [ -f "$MCP_FILE" ] && [ -f "$SOURCE_MCP" ]; then
        # Merge new servers into existing mcpServers object
        NEW_SERVERS=$(cat "$SOURCE_MCP")
        MERGED=$(${pkgs.jq}/bin/jq --argjson new "$NEW_SERVERS" '
          .mcpServers = (.mcpServers // {}) + $new
        ' "$MCP_FILE")
        if [ -n "$MERGED" ]; then
          echo "$MERGED" > "$MCP_FILE"
          echo "Claude Code MCP servers merged"
        fi
      fi

      # Ensure session log exists
      $DRY_RUN_CMD touch "$CLAUDE_DIR/session.log"

      # ========================================
      # improvements.jsonl - Initialize if missing
      # ========================================
      IMPROVEMENTS_FILE="$CLAUDE_DIR/improvements.jsonl"
      if [ ! -f "$IMPROVEMENTS_FILE" ]; then
        echo "" > "$IMPROVEMENTS_FILE"
        echo "Claude Code improvements.jsonl initialized"
      fi

      # ========================================
      # metrics/ - Initialize directory and baseline
      # ========================================
      METRICS_DIR="$CLAUDE_DIR/metrics"
      $DRY_RUN_CMD mkdir -p "$METRICS_DIR"
      if [ ! -f "$METRICS_DIR/baseline.json" ]; then
        cat > "$METRICS_DIR/baseline.json" << 'BASELINE'
{
  "version": "4.0.0",
  "installed": "$(date -Iseconds)",
  "calibration": {
    "brierScore": null,
    "predictions": [],
    "confidenceMultiplier": 1.0
  },
  "evolution": {
    "memoryEntries": 0,
    "toolsActive": 0,
    "lastEvolution": null
  },
  "safety": {
    "violations": 0,
    "lastCheck": null,
    "streakDays": 0
  }
}
BASELINE
        echo "Claude Code metrics baseline initialized"
      fi
    '';
  };
}
