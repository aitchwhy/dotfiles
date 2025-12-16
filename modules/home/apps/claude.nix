# Claude Desktop and Claude Code MCP server configuration
# Single source of truth for all MCP servers
#
# This module generates:
# 1. Claude Desktop config (~/Library/Application Support/Claude/claude_desktop_config.json)
#    - Uses /bin/sh wrapper to inject Nix PATH for Electron app compatibility
# 2. Claude Code CLI config (~/.claude.json via agents.nix)
#    - Uses direct npx commands (shell PATH already available)
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mapAttrs
    mkEnableOption
    mkIf
    ;

  # Determinate Nix profile paths (in priority order)
  nixPaths = [
    "/etc/profiles/per-user/hank/bin"
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"
    "$HOME/.nix-profile/bin"
    "$HOME/.local/bin" # For uvx (Python MCP servers)
  ];
  pathString = concatStringsSep ":" nixPaths;

  # ═══════════════════════════════════════════════════════════════════════════
  # SINGLE SOURCE OF TRUTH: MCP Server Definitions
  # ═══════════════════════════════════════════════════════════════════════════
  # Add/remove servers here - both Desktop and CLI configs auto-generate
  mcpServerDefs = {
    memory = {
      package = "@modelcontextprotocol/server-memory";
      args = [ ];
    };
    filesystem = {
      package = "@modelcontextprotocol/server-filesystem";
      args = [
        "${config.home.homeDirectory}/src"
        "${config.home.homeDirectory}/dotfiles"
        "${config.home.homeDirectory}/Documents"
      ];
    };
    # git server removed - GitHub MCP server provides richer functionality
    sequential-thinking = {
      package = "@modelcontextprotocol/server-sequential-thinking";
      args = [ ];
    };
    context7 = {
      package = "@upstash/context7-mcp";
      args = [ ];
    };
    fetch = {
      package = "mcp-server-fetch"; # Python package via uvx
      args = [ ];
      isPython = true;
    };
    repomix = {
      package = "repomix";
      args = [ "--mcp" ];
    };
    signet = {
      # Local MCP server for Signet code quality
      command = "bun";
      args = [
        "run"
        "${config.home.homeDirectory}/dotfiles/config/quality/src/mcp-server.ts"
      ];
      isLocal = true; # Not an npx package
    };
    github = {
      # GitHub API: repos, issues, PRs, code search
      # Token sourced from sops-nix secret file
      package = "@modelcontextprotocol/server-github";
      args = [ ];
      hasEnvFile = true; # Signal to wrapper to source GITHUB_PERSONAL_ACCESS_TOKEN
    };
    playwright = {
      # Browser automation for testing and web interactions
      package = "@playwright/mcp";
      args = [ ];
    };
    ast-grep = {
      # AST-based structural code search across 20+ languages
      package = "@notprolands/ast-grep-mcp";
      args = [ ];
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # Format Generators
  # ═══════════════════════════════════════════════════════════════════════════

  # Claude Desktop format: wrap commands in /bin/sh to inject Nix PATH
  # Electron apps don't inherit shell PATH, so we must inject it
  toDesktopFormat =
    _name: def:
    let
      argsString = if def.args == [ ] then "" else " " + (concatStringsSep " " def.args);
      # Source GitHub token from sops-nix decrypted file if hasEnvFile is set
      envSource =
        if def.hasEnvFile or false then
          "[ -f $HOME/.config/claude/github-token ] && export GITHUB_PERSONAL_ACCESS_TOKEN=$(cat $HOME/.config/claude/github-token); "
        else
          "";
    in
    if def.isLocal or false then
      {
        # Local servers (e.g., bun scripts) - wrap with PATH injection
        command = "/bin/sh";
        args = [
          "-c"
          "${envSource}PATH=${pathString}:$PATH exec ${def.command}${argsString}"
        ];
      }
    else if def.isPython or false then
      {
        # Python packages via uvx
        command = "/bin/sh";
        args = [
          "-c"
          "${envSource}PATH=${pathString}:$PATH exec uvx ${def.package}${argsString}"
        ];
      }
    else
      {
        # npm packages via npx
        command = "/bin/sh";
        args = [
          "-c"
          "${envSource}PATH=${pathString}:$PATH exec npx -y ${def.package}${argsString}"
        ];
      };

  # Claude Code CLI format: direct commands (shell has PATH)
  # For servers needing env vars (like GitHub), we wrap in sh to source the token
  toCliFormat =
    _name: def:
    let
      envSource =
        if def.hasEnvFile or false then
          "[ -f $HOME/.config/claude/github-token ] && export GITHUB_PERSONAL_ACCESS_TOKEN=$(cat $HOME/.config/claude/github-token); "
        else
          "";
      needsWrapper = def.hasEnvFile or false;
    in
    if def.isLocal or false then
      {
        command = def.command;
        args = def.args;
        type = "stdio";
      }
    else if def.isPython or false then
      {
        # Python packages via uvx
        command = "uvx";
        args = [ def.package ] ++ def.args;
        type = "stdio";
      }
    else if needsWrapper then
      {
        # npm packages that need env vars - wrap in shell
        command = "/bin/sh";
        args = [
          "-c"
          "${envSource}exec npx -y ${def.package}${
            if def.args == [ ] then "" else " " + (concatStringsSep " " def.args)
          }"
        ];
        type = "stdio";
      }
    else
      {
        # npm packages via npx
        command = "npx";
        args = [
          "-y"
          def.package
        ]
        ++ def.args;
        type = "stdio";
      };

  # Generate both formats
  desktopMcpServers = mapAttrs toDesktopFormat mcpServerDefs;
  cliMcpServers = mapAttrs toCliFormat mcpServerDefs;

  # Config JSON for Claude Desktop
  desktopConfigJson = builtins.toJSON { mcpServers = desktopMcpServers; };

  # Config JSON for Claude Code CLI (used by agents.nix)
  cliConfigJson = builtins.toJSON cliMcpServers;
in
{
  options.modules.home.apps.claude = {
    enable = mkEnableOption "Claude Desktop and Code MCP servers";

    # Expose CLI config for agents.nix to use
    cliMcpServersJson = lib.mkOption {
      type = lib.types.str;
      default = cliConfigJson;
      readOnly = true;
      description = "Generated MCP servers JSON for Claude Code CLI";
    };
  };

  config = mkIf config.modules.home.apps.claude.enable {
    # Claude Desktop stores config in ~/Library/Application Support/Claude/
    home.file."Library/Application Support/Claude/claude_desktop_config.json" = {
      text = desktopConfigJson;
    };

    # Generate mcp-servers.json for Claude Code CLI (used by agents.nix)
    # This replaces the manually maintained config/agents/mcp-servers.json
    xdg.configFile."claude/mcp-servers.json" = {
      text = cliConfigJson;
    };
  };
}
