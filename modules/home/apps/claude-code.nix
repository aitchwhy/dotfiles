# Claude Code CLI configuration
# Manages ~/.claude/ directory with CLAUDE.md, settings, commands, agents, skills
# Note: This is SEPARATE from claude.nix which manages Claude Desktop
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.modules.home.apps.claudeCode = {
    enable = mkEnableOption "Claude Code CLI configuration";
  };

  config = mkIf config.modules.home.apps.claudeCode.enable {
    # jq required for JSON merging
    home.packages = [ pkgs.jq ];

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
      ".claude/skills/typescript-patterns".source =
        ../../../config/claude-code/skills/typescript-patterns;
      ".claude/skills/zod-patterns".source = ../../../config/claude-code/skills/zod-patterns;
      ".claude/skills/result-patterns".source = ../../../config/claude-code/skills/result-patterns;
      ".claude/skills/tdd-patterns".source = ../../../config/claude-code/skills/tdd-patterns;
      ".claude/skills/nix-darwin-patterns".source =
        ../../../config/claude-code/skills/nix-darwin-patterns;
      ".claude/skills/observability-patterns".source =
        ../../../config/claude-code/skills/observability-patterns;
      ".claude/skills/clean-code".source = ../../../config/claude-code/skills/clean-code;
      ".claude/skills/twelve-factor".source = ../../../config/claude-code/skills/twelve-factor;
      ".claude/skills/verification-first".source =
        ../../../config/claude-code/skills/verification-first;
    };

    # Mutable configs (merge/copy-on-init pattern with backup and validation)
    home.activation.claudeCodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      CLAUDE_DIR="$HOME/.claude"
      SETTINGS_FILE="$CLAUDE_DIR/settings.json"
      MCP_FILE="$HOME/.claude.json"
      BACKUP_DIR="$CLAUDE_DIR/backups"
      SOURCE_SETTINGS="${../../../config/claude-code/settings.json}"
      SOURCE_MCP="${../../../config/claude-code/mcp-servers.json}"

      $DRY_RUN_CMD mkdir -p "$CLAUDE_DIR" "$CLAUDE_DIR/skills" "$BACKUP_DIR"

      # ========================================
      # settings.json - merge with backup
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
        # Backup before merge
        $DRY_RUN_CMD cp "$SETTINGS_FILE" "$BACKUP_DIR/settings.$(date +%Y%m%d%H%M%S).json"

        # Existing file - merge hooks/permissions, enforce enabledPlugins from source
        MERGED=$(${pkgs.jq}/bin/jq -s '
          .[0] as $existing | .[1] as $source |
          $existing * {
            permissions: ($existing.permissions // {}) * $source.permissions,
            hooks: ($existing.hooks // {}) * $source.hooks,
            enabledPlugins: $source.enabledPlugins
          }
        ' "$SETTINGS_FILE" "$SOURCE_SETTINGS" 2>/dev/null)

        # Validate merged JSON before writing
        if [ -n "$MERGED" ] && echo "$MERGED" | ${pkgs.jq}/bin/jq empty 2>/dev/null; then
          echo "$MERGED" > "$SETTINGS_FILE"
          echo "Claude Code settings.json merged (hooks + permissions)"
        else
          echo "WARNING: Merge failed, keeping existing settings.json"
        fi
      fi

      # ========================================
      # ~/.claude.json - merge MCP servers with backup
      # ========================================
      if [ -f "$MCP_FILE" ] && [ -f "$SOURCE_MCP" ]; then
        # Backup before merge
        $DRY_RUN_CMD cp "$MCP_FILE" "$BACKUP_DIR/claude.$(date +%Y%m%d%H%M%S).json"

        # Merge new servers into existing mcpServers object
        NEW_SERVERS=$(cat "$SOURCE_MCP")
        MERGED=$(${pkgs.jq}/bin/jq --argjson new "$NEW_SERVERS" '
          .mcpServers = (.mcpServers // {}) + $new
        ' "$MCP_FILE" 2>/dev/null)

        # Validate merged JSON before writing
        if [ -n "$MERGED" ] && echo "$MERGED" | ${pkgs.jq}/bin/jq empty 2>/dev/null; then
          echo "$MERGED" > "$MCP_FILE"
          echo "Claude Code MCP servers merged"
        else
          echo "WARNING: MCP merge failed, keeping existing ~/.claude.json"
        fi
      elif [ ! -f "$MCP_FILE" ] && [ -f "$SOURCE_MCP" ]; then
        # Initialize new ~/.claude.json
        echo "{\"mcpServers\": $(cat "$SOURCE_MCP")}" > "$MCP_FILE"
        echo "Claude Code ~/.claude.json initialized"
      fi

      # Cleanup old backups (keep last 5)
      ls -t "$BACKUP_DIR"/*.json 2>/dev/null | tail -n +6 | xargs -r rm -f

      # Ensure session log exists
      $DRY_RUN_CMD touch "$CLAUDE_DIR/session.log"

      echo "Claude Code v7.0 configuration ready (verification-first)"
    '';
  };
}
