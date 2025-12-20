# Unified AI Agent Configuration
# Manages Claude Code CLI, Gemini CLI, and Antigravity IDE configs
# Single source of truth for AGENT.md, MCP servers, commands, skills
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  agentsDir = "${config.home.homeDirectory}/dotfiles/config/agents";
in
{
  options.modules.home.apps.agents = {
    enable = mkEnableOption "Unified AI agent configuration";
  };

  config = mkIf config.modules.home.apps.agents.enable {
    # jq required for JSON merging
    home.packages = [ pkgs.jq ];

    # Static configs (immutable - symlinked)
    home.file = {
      # ========================================
      # Claude Code CLI
      # ========================================
      ".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${agentsDir}/AGENTS.md";
      ".claude/settings.json".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/settings/claude-code.json";
      ".claude/commands".source = config.lib.file.mkOutOfStoreSymlink "${agentsDir}/commands";
      ".claude/agents".source = config.lib.file.mkOutOfStoreSymlink "${agentsDir}/agents";
      ".claude/rules".source = config.lib.file.mkOutOfStoreSymlink "${agentsDir}/rules";
      ".claude/memory".source = config.lib.file.mkOutOfStoreSymlink "${agentsDir}/memory";

      # Skills - project-specific patterns
      ".claude/skills/tanstack-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/tanstack-patterns";
      ".claude/skills/livekit-agents".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/livekit-agents";

      # Skills - general TypeScript/engineering patterns
      ".claude/skills/typescript-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/typescript-patterns";
      ".claude/skills/zod-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/zod-patterns";
      ".claude/skills/tdd-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/tdd-patterns";
      ".claude/skills/observability-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/observability-patterns";
      ".claude/skills/quality-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/quality-patterns";
      ".claude/skills/signet-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/signet-patterns";

      # Skills - architecture patterns
      ".claude/skills/effect-ts-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/effect-ts-patterns";
      ".claude/skills/hexagonal-architecture".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/hexagonal-architecture";
      ".claude/skills/devops-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/devops-patterns";

      # Skills - Nix patterns
      ".claude/skills/nix-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/nix-patterns";
      ".claude/skills/nix-infrastructure".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/nix-infrastructure";
      ".claude/skills/nix-build-optimization".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/nix-build-optimization";
      ".claude/skills/nix-configuration-centralization".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/nix-configuration-centralization";

      ".claude/skills/typespec-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/typespec-patterns";
      ".claude/skills/refactoring-catalog".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/refactoring-catalog";
      ".claude/skills/formal-verification".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/formal-verification";
      ".claude/skills/semantic-codebase".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/semantic-codebase";
      ".claude/skills/planning-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/planning-patterns";

      # Skills - MCP server references
      ".claude/skills/repomix".source = config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/repomix";
      ".claude/skills/context7-mcp".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/context7-mcp";
      ".claude/skills/mcp-optimization".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/mcp-optimization";

      # Skills - additional patterns
      ".claude/skills/state-machine-patterns".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/state-machine-patterns";
      ".claude/skills/secrets-management".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/secrets-management";
      ".claude/skills/paragon".source = config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/paragon";
      ".claude/skills/codebase-exposure".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/skills/codebase-exposure";

      # ========================================
      # Gemini CLI
      # ========================================
      ".gemini/GEMINI.md".source = config.lib.file.mkOutOfStoreSymlink "${agentsDir}/AGENTS.md";
      ".gemini/settings.json".source =
        config.lib.file.mkOutOfStoreSymlink "${agentsDir}/settings/gemini.json";
      ".gemini/rules".source = config.lib.file.mkOutOfStoreSymlink "${agentsDir}/rules";
      ".gemini/memory".source = config.lib.file.mkOutOfStoreSymlink "${agentsDir}/memory";
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
      agent-setup = "ln -sf ${agentsDir}/AGENTS.md ./CLAUDE.md && ln -sf ${agentsDir}/AGENTS.md ./GEMINI.md && echo 'Agent context linked'";
      agent-clean = "rm -f ./CLAUDE.md ./GEMINI.md && echo 'Agent context removed'";
    };

    # Mutable configs (MCP servers need merge pattern for user additions)
    home.activation.agentsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      CLAUDE_DIR="$HOME/.claude"
      MCP_FILE="$HOME/.claude.json"
      BACKUP_DIR="$CLAUDE_DIR/backups"
      # MCP servers generated by modules/home/apps/claude.nix (single source of truth)
      SOURCE_MCP="$HOME/.config/claude/mcp-servers.json"

      $DRY_RUN_CMD mkdir -p "$CLAUDE_DIR" "$CLAUDE_DIR/skills" "$BACKUP_DIR"
      $DRY_RUN_CMD mkdir -p "$HOME/.gemini/antigravity"

      # Remove old settings.json if it exists (now managed by symlink)
      if [ -f "$CLAUDE_DIR/settings.json" ] && [ ! -L "$CLAUDE_DIR/settings.json" ]; then
        $DRY_RUN_CMD cp "$CLAUDE_DIR/settings.json" "$BACKUP_DIR/settings.$(date +%Y%m%d%H%M%S).json"
        $DRY_RUN_CMD rm "$CLAUDE_DIR/settings.json"
        echo "Backed up and removed old settings.json (now symlinked)"
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
