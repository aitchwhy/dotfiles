# Generic MCP Server Single Source of Truth
# Generates configs for: Claude Desktop, Claude Code CLI, Gemini CLI, and other agentic IDEs
#
# This module generates:
# 1. Claude Desktop config (~/Library/Application Support/Claude/claude_desktop_config.json)
#    - Uses /bin/sh wrapper to inject Nix PATH for Electron app compatibility
# 2. Claude Code CLI config (~/.config/claude/mcp-servers.json)
#    - Uses direct npx commands (shell PATH already available)
#
# Token Optimization (December 2025):
# - Reduced from 16 to 6 MCP servers
# - Uses SOTA servers: Ref.tools (60-95% fewer tokens), Exa AI (code search)
# - Removed redundant servers that duplicate native Claude Code capabilities
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mapAttrs
    filterAttrs
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

  # Generic MCP secrets path (shared across Claude, Gemini, Cursor, etc.)
  mcpSecretsPath = "$HOME/.config/mcp";

  # ═══════════════════════════════════════════════════════════════════════════
  # SINGLE SOURCE OF TRUTH: MCP Server Definitions (Optimized December 2025)
  # ═══════════════════════════════════════════════════════════════════════════
  # Target: <25k tokens (down from ~116k)
  # Strategy: SOTA search/docs (Ref, Exa) + unique capabilities only
  mcpServerDefs = {
    # ═══════════════════════════════════════════════════════════════════════════
    # DOCUMENTATION & SEARCH (State-of-the-Art - December 2025)
    # ═══════════════════════════════════════════════════════════════════════════

    ref = {
      # Ref.tools - 60-95% fewer tokens than context7/fetch alternatives
      # Context-aware documentation search with session deduplication
      # https://ref.tools/
      isHttp = true;
      url = "https://api.ref.tools/mcp";
      # API key will be appended at activation time from sops-nix
      apiKeyPath = "${mcpSecretsPath}/ref-api-key";
    };

    exa = {
      # Exa AI - Code context search across billions of repos
      # Tools: get_code_context_exa, web_search_exa
      # https://exa.ai/
      package = "exa-mcp-server";
      args = [ ];
      envVars = {
        EXA_API_KEY = "${mcpSecretsPath}/exa-api-key";
      };
    };

    # ═══════════════════════════════════════════════════════════════════════════
    # UNIQUE CAPABILITIES (No native Claude Code equivalent)
    # ═══════════════════════════════════════════════════════════════════════════

    github = {
      # GitHub API: repos, issues, PRs, code search
      # Token sourced from sops-nix secret file
      package = "@modelcontextprotocol/server-github";
      args = [ ];
      envVars = {
        GITHUB_PERSONAL_ACCESS_TOKEN = "${mcpSecretsPath}/github-token";
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

    repomix = {
      # Codebase packaging for AI analysis
      package = "repomix";
      args = [ "--mcp" ];
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

  # Filter out HTTP servers for stdio format generators
  stdioServerDefs = filterAttrs (_name: def: !(def.isHttp or false)) mcpServerDefs;

  # Claude Desktop format: wrap commands in /bin/sh to inject Nix PATH
  # Electron apps don't inherit shell PATH, so we must inject it
  toDesktopFormat =
    _name: def:
    let
      argsString = if def.args or [ ] == [ ] then "" else " " + (concatStringsSep " " def.args);
      envSource = mkEnvSource def;
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
  # For servers needing env vars, we wrap in sh to source secrets
  toCliFormat =
    _name: def:
    let
      envSource = mkEnvSource def;
      needsWrapper = (def.envVars or { }) != { };
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

  # Generate stdio server configs
  desktopStdioServers = mapAttrs toDesktopFormat stdioServerDefs;
  cliStdioServers = mapAttrs toCliFormat stdioServerDefs;

  # Pre-compute JSON fragments for activation script (strip outer braces)
  desktopStdioJson = builtins.toJSON desktopStdioServers;
  desktopStdioFragment = builtins.substring 1 (builtins.stringLength desktopStdioJson - 2) desktopStdioJson;

  cliStdioJson = builtins.toJSON cliStdioServers;
  cliStdioFragment = builtins.substring 1 (builtins.stringLength cliStdioJson - 2) cliStdioJson;

  # Config JSON for Claude Code CLI (stdio servers only - HTTP added at activation)
  cliConfigJson = builtins.toJSON cliStdioServers;
in
{
  options.modules.home.apps.mcp = {
    enable = mkEnableOption "MCP servers for Claude Desktop, Code CLI, and other agentic IDEs";

    # Expose CLI config for other modules to use
    cliMcpServersJson = lib.mkOption {
      type = lib.types.str;
      default = cliConfigJson;
      readOnly = true;
      description = "Generated MCP servers JSON for Claude Code CLI";
    };
  };

  config = mkIf config.modules.home.apps.mcp.enable {
    # ═══════════════════════════════════════════════════════════════════════════
    # Claude Settings & Skills (SSOT - symlinks to Quality System generated files)
    # ═══════════════════════════════════════════════════════════════════════════

    home.file.".claude/settings.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/quality/generated/claude/settings.json";
    };

    home.file.".claude/skills" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/quality/generated/claude/skills";
    };

    home.file.".claude/agents" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/quality/generated/claude/personas";
    };

    # ═══════════════════════════════════════════════════════════════════════════
    # MCP Config Generation (Activation-time for HTTP server API key injection)
    # ═══════════════════════════════════════════════════════════════════════════

    # Generate MCP configs at activation time (after sops decryption)
    # This allows HTTP servers like Ref to have API keys injected into URLs
    home.activation.generateMcpConfigs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      MCP_SECRETS="${config.home.homeDirectory}/.config/mcp"

      # Read API key for Ref HTTP server
      REF_KEY=""
      if [ -f "$MCP_SECRETS/ref-api-key" ]; then
        REF_KEY=$(cat "$MCP_SECRETS/ref-api-key")
      fi

      # Generate Claude Desktop config with HTTP servers
      DESKTOP_CONFIG="${config.home.homeDirectory}/Library/Application Support/Claude/claude_desktop_config.json"
      mkdir -p "$(dirname "$DESKTOP_CONFIG")"

      # Combine stdio servers (from Nix) with HTTP servers (runtime key injection)
      cat > "$DESKTOP_CONFIG" << DESKTOPEOF
{
  "mcpServers": {
    "ref": {
      "type": "http",
      "url": "https://api.ref.tools/mcp?apiKey=$REF_KEY"
    },
    ${desktopStdioFragment}
  }
}
DESKTOPEOF

      # Generate Claude Code CLI config with HTTP servers
      CLI_CONFIG="${config.home.homeDirectory}/.config/claude/mcp-servers.json"
      mkdir -p "$(dirname "$CLI_CONFIG")"

      cat > "$CLI_CONFIG" << CLIEOF
{
  "ref": {
    "type": "http",
    "url": "https://api.ref.tools/mcp?apiKey=$REF_KEY"
  },
  ${cliStdioFragment}
}
CLIEOF

      echo "MCP configs generated (6 servers: ref, exa, github, playwright, ast-grep, repomix)"
    '';

    # Generate Quality System artifacts (skills, personas, rules, settings)
    # Runs after writeBoundary to ensure all files are in place
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
