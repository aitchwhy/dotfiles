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
    filesystem = {
      package = "@modelcontextprotocol/server-filesystem";
      args = [
        "${config.home.homeDirectory}/src"
        "${config.home.homeDirectory}/dotfiles"
        "${config.home.homeDirectory}/Documents"
      ];
    };
    git = {
      # Git repository operations - read, search, manipulate repos
      package = "mcp-server-git";
      args = [ ];
      isPython = true;
    };
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
    github = {
      # GitHub API: repos, issues, PRs, code search
      # Token sourced from sops-nix secret file
      package = "@modelcontextprotocol/server-github";
      args = [ ];
      envVars = {
        GITHUB_PERSONAL_ACCESS_TOKEN = "$HOME/.config/claude/github-token";
      };
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

    # ═══════════════════════════════════════════════════════════════════════════
    # Stack-specific MCP servers (Ember-Dash-Platform alignment)
    # ═══════════════════════════════════════════════════════════════════════════
    # NOTE: jsrepo removed - @jsrepo/mcp outputs non-JSON to stdout (MCP protocol violation)
    docker = {
      # Container and compose stack management
      package = "mcp-server-docker";
      args = [ ];
      isPython = true;
    };
    shadcn = {
      # Official shadcn/ui MCP - components, blocks, demos for React/Tailwind
      # https://ui.shadcn.com/docs/mcp
      package = "shadcn@latest";
      args = [ "mcp" ];
    };
    chrome-devtools = {
      # Chrome DevTools Protocol - browser debugging, performance, network
      package = "chrome-devtools-mcp";
      args = [ ];
    };
    reactbits = {
      # React Bits - 135+ animated React components (buttons, backgrounds, text effects)
      # https://reactbits.dev - provides component code and Tailwind/CSS variants
      package = "reactbits-dev-mcp-server";
      args = [ ];
    };

    # ═══════════════════════════════════════════════════════════════════════════
    # Modern CLI Tool MCP Servers (schema-based enforcement)
    # ═══════════════════════════════════════════════════════════════════════════
    ripgrep = {
      # Ripgrep search with proper schema - enforces correct flag usage
      # Replaces: grep --include → rg --glob
      package = "mcp-ripgrep";
      args = [ ];
    };
    # NOTE: postgres removed - requires connection URL arg, package is deprecated

    # ═══════════════════════════════════════════════════════════════════════════
    # Observability & Infrastructure MCP Servers
    # ═══════════════════════════════════════════════════════════════════════════
    datadog = {
      # Query logs, metrics, monitors, dashboards, incidents
      # https://github.com/GeLi2001/datadog-mcp-server
      package = "datadog-mcp-server";
      args = [ ];
      envVars = {
        DD_API_KEY = "$HOME/.config/claude/datadog-api-key";
        DD_APP_KEY = "$HOME/.config/claude/datadog-app-key";
      };
    };

    pulumi = {
      # Pulumi Cloud: stacks, resources, registry, Neo agent
      # OAuth via browser - no local credentials stored
      isRemote = true;
      url = "https://mcp.ai.pulumi.com/mcp";
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # Format Generators
  # ═══════════════════════════════════════════════════════════════════════════

  # Generic env sourcing from sops-nix decrypted files
  # Uses semicolon (not &&) for independent sourcing - missing files don't block others
  mkEnvSource =
    def:
    let
      envVars = def.envVars or { };
      sources = lib.mapAttrsToList (
        name: path: "[ -f ${path} ] && export ${name}=$(cat ${path})"
      ) envVars;
    in
    if sources == [ ] then "" else (lib.concatStringsSep "; " sources) + "; ";

  # Claude Desktop format: wrap commands in /bin/sh to inject Nix PATH
  # Electron apps don't inherit shell PATH, so we must inject it
  toDesktopFormat =
    _name: def:
    let
      argsString = if def.args or [ ] == [ ] then "" else " " + (concatStringsSep " " def.args);
      envSource = mkEnvSource def;
    in
    # Remote MCP servers (HTTP transport, e.g., Pulumi OAuth)
    if def.isRemote or false then
      {
        type = "http";
        url = def.url;
      }
    else if def.isLocal or false then
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
  # For servers needing env vars, we wrap in sh to source secrets
  toCliFormat =
    _name: def:
    let
      envSource = mkEnvSource def;
      needsWrapper = (def.envVars or { }) != { };
    in
    # Remote MCP servers (HTTP transport, e.g., Pulumi OAuth)
    if def.isRemote or false then
      {
        type = "http";
        url = def.url;
      }
    else if def.isLocal or false then
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

    # Settings SSOT - symlink prevents drift
    # Points to generated settings from Quality System
    home.file.".claude/settings.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/quality/generated/claude/settings.json";
    };

    # Skills symlink - generated from TypeScript definitions
    home.file.".claude/skills" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/quality/generated/claude/skills";
    };

    # Personas symlink - generated from TypeScript definitions
    home.file.".claude/agents" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/quality/generated/claude/personas";
    };

    # Generate mcp-servers.json for Claude Code CLI (used by agents.nix)
    # This replaces the manually maintained config/agents/mcp-servers.json
    xdg.configFile."claude/mcp-servers.json" = {
      text = cliConfigJson;
    };

    # Generate Quality System artifacts (skills, personas, rules, settings)
    # Runs after writeBoundary to ensure all files are in place
    # Errors are NOT swallowed - generation must succeed
    #
    # NOTE: We use absolute path to bun because:
    # 1. PATH is not available during home-manager activation
    # 2. builtins.pathExists evaluates at Nix build time, not runtime
    # 3. This path is stable - it's where nix-darwin installs user packages
    home.activation.generateQuality = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      QUALITY_DIR="${config.home.homeDirectory}/dotfiles/config/quality"
      BUN="/etc/profiles/per-user/${config.home.username}/bin/bun"

      if [ -f "$QUALITY_DIR/package.json" ]; then
        echo "Generating Intelligence artifacts..."
        cd "$QUALITY_DIR"

        if ! $BUN install --frozen-lockfile; then
          echo "ERROR: bun install failed in $QUALITY_DIR"
          exit 1
        fi

        if ! $BUN run generate; then
          echo "ERROR: Intelligence generation failed in $QUALITY_DIR"
          exit 1
        fi

        echo "Intelligence System artifacts generated successfully"
      fi
    '';
  };
}
