# Unified AI Agent Configuration
# Manages Claude Code CLI, Gemini CLI, and Antigravity IDE configs
# Single source of truth for AGENT.md, MCP servers, commands, skills
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  agentsDir = "${config.home.homeDirectory}/dotfiles/config/agents";
in {
  options.modules.home.apps.agents = {
    enable = mkEnableOption "Unified AI agent configuration";
  };

  config = mkIf config.modules.home.apps.agents.enable {
    # jq required for JSON merging
    home.packages = [pkgs.jq];

    # Static configs (immutable - symlinked)
    home.file = {
      # ========================================
      # Claude Code CLI
      # ========================================
      ".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${agentsDir}/AGENT.md";
      ".claude/commands".source = config.lib.file.mkOutOfStoreSymlink "${agentsDir}/commands";
      ".claude/agents".source = config.lib.file.mkOutOfStoreSymlink "${agentsDir}/agents";

      # Skills - project-specific patterns
      ".claude/skills/hono-workers".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/hono-workers";
      ".claude/skills/tanstack-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/tanstack-patterns";
      ".claude/skills/livekit-agents".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/livekit-agents";

      # Skills - general TypeScript/engineering patterns
      ".claude/skills/typescript-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/typescript-patterns";
      ".claude/skills/zod-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/zod-patterns";
      ".claude/skills/result-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/result-patterns";
      ".claude/skills/tdd-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/tdd-patterns";
      ".claude/skills/nix-darwin-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/nix-darwin-patterns";
      ".claude/skills/observability-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/observability-patterns";
      ".claude/skills/clean-code".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/clean-code";
      ".claude/skills/twelve-factor".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/twelve-factor";
      ".claude/skills/verification-first".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/verification-first";
      ".claude/skills/signet-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/signet-patterns";
      ".claude/skills/repomix-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/repomix-patterns";

      # Skills - architecture patterns
      ".claude/skills/effect-ts-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/effect-ts-patterns";
      ".claude/skills/hexagonal-architecture".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/hexagonal-architecture";
      ".claude/skills/devops-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/devops-patterns";

      # Skills - Nix patterns
      ".claude/skills/nix-flake-parts".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/nix-flake-parts";

      # Skills - API patterns
      ".claude/skills/typespec-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/typespec-patterns";
      ".claude/skills/signet-generator-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/signet-generator-patterns";

      # Skills - quality patterns
      ".claude/skills/refactoring-catalog".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/refactoring-catalog";
      ".claude/skills/distributed-systems-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/distributed-systems-patterns";
      ".claude/skills/code-smells".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/code-smells";
      ".claude/skills/formal-verification".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/formal-verification";
      ".claude/skills/semantic-codebase".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/semantic-codebase";
      ".claude/skills/commit-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/commit-patterns";
      ".claude/skills/planning-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/planning-patterns";

      # ========================================
      # Gemini CLI
      # ========================================
      ".gemini/GEMINI.md".source = config.lib.file.mkOutOfStoreSymlink "${agentsDir}/AGENT.md";
      ".gemini/settings.json".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/settings/gemini.json";
      # MCP servers generated by modules/home/apps/claude.nix (single source of truth)
      ".gemini/mcp-servers.json".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/claude/mcp-servers.json";

      # ========================================
      # Antigravity IDE
      # ========================================
      # MCP servers generated by modules/home/apps/claude.nix (single source of truth)
      ".gemini/antigravity/mcp_config.json".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/claude/mcp-servers.json";
    };

    # Shell aliases for project setup
    programs.zsh.shellAliases = {
      agent-setup = "ln -sf ${agentsDir}/AGENT.md ./CLAUDE.md && ln -sf ${agentsDir}/AGENT.md ./GEMINI.md && echo '✓ Agent context linked'";
      agent-clean = "rm -f ./CLAUDE.md ./GEMINI.md && echo '✓ Agent context removed'";
    };

    # Mutable configs (merge/copy-on-init pattern with backup and validation)
    home.activation.agentsConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      CLAUDE_DIR="$HOME/.claude"
      SETTINGS_FILE="$CLAUDE_DIR/settings.json"
      MCP_FILE="$HOME/.claude.json"
      BACKUP_DIR="$CLAUDE_DIR/backups"
      SOURCE_SETTINGS="${agentsDir}/settings/claude-code.json"
      # MCP servers generated by modules/home/apps/claude.nix (single source of truth)
      SOURCE_MCP="$HOME/.config/claude/mcp-servers.json"

      $DRY_RUN_CMD mkdir -p "$CLAUDE_DIR" "$CLAUDE_DIR/skills" "$BACKUP_DIR"
      $DRY_RUN_CMD mkdir -p "$HOME/.gemini/antigravity"

      # ========================================
      # Claude Code: settings.json - merge with backup
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
      # Claude Code: ~/.claude.json - merge MCP servers with backup
      # ========================================
      # Clean up stale MCP servers that were removed from source.
      # This prevents leftover servers from previous configs that may
      # no longer be valid or desired. Only keeps servers that exist
      # in the current source configuration.
      if [ -f "$MCP_FILE" ] && [ -f "$SOURCE_MCP" ]; then
        # Remove servers not in source (stale entries from previous configs)
        CLEANED=$(${pkgs.jq}/bin/jq --argjson source "$(cat "$SOURCE_MCP")" '
          .mcpServers = (.mcpServers // {} | to_entries | map(select(.key as $k | $source | has($k))) | from_entries)
        ' "$MCP_FILE" 2>/dev/null)
        if [ -n "$CLEANED" ] && echo "$CLEANED" | ${pkgs.jq}/bin/jq empty 2>/dev/null; then
          echo "$CLEANED" > "$MCP_FILE"
          echo "Cleaned stale MCP servers"
        else
          echo "WARNING: MCP cleanup failed, keeping existing ~/.claude.json"
        fi
      fi

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

      echo "Unified agent configuration ready (Claude Code + Gemini CLI + Antigravity)"
    '';
  };
}
