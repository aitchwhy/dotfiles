# Claude Desktop MCP server configuration
# Uses /bin/sh wrapper to inject Nix PATH for Electron app compatibility
# Electron apps don't inherit shell PATH, so we must explicitly inject Nix paths
#
# NOTE: Keep MCP servers in sync with config/agents/mcp-servers.json
# This module uses wrapNpxCommand for Electron PATH compatibility.
# Claude Code CLI uses direct npx commands (see agents.nix).
{
  config,
  lib,
  ...
}:
let
  inherit (lib) concatStringsSep mkEnableOption mkIf;
  # Determinate Nix profile paths (in priority order)
  # Primary: /etc/profiles/per-user/hank/bin (where npx actually lives)
  # Fallbacks for different Nix setups
  nixPaths = [
    "/etc/profiles/per-user/hank/bin"
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"
    "$HOME/.nix-profile/bin"
  ];
  pathString = concatStringsSep ":" nixPaths;

  # Wrapper to inject PATH for Electron apps that can't find Nix binaries
  wrapNpxCommand =
    pkg: extraArgs:
    let
      argsString = if extraArgs == [ ] then "" else " " + (concatStringsSep " " extraArgs);
    in
    {
      command = "/bin/sh";
      args = [
        "-c"
        "PATH=${pathString}:$PATH exec npx -y ${pkg}${argsString}"
      ];
    };

  mcpServers = {
    # Keep in sync with config/agents/mcp-servers.json
    memory = wrapNpxCommand "@modelcontextprotocol/server-memory" [ ];
    filesystem = wrapNpxCommand "@modelcontextprotocol/server-filesystem" [
      "$HOME/src"
      "$HOME/dotfiles"
      "$HOME/Documents"
    ];
    git = wrapNpxCommand "@modelcontextprotocol/server-git" [ ];
    "sequential-thinking" = wrapNpxCommand "@modelcontextprotocol/server-sequential-thinking" [ ];
    context7 = wrapNpxCommand "@upstash/context7-mcp" [ ];
    fetch = wrapNpxCommand "@modelcontextprotocol/server-fetch" [ ];
    repomix = wrapNpxCommand "repomix" [ "--mcp" ];
  };

  configJson = builtins.toJSON { inherit mcpServers; };
in
{
  options.modules.home.apps.claude = {
    enable = mkEnableOption "Claude Desktop MCP servers";
  };

  config = mkIf config.modules.home.apps.claude.enable {
    # Claude Desktop stores config in ~/Library/Application Support/Claude/
    # This is a macOS-specific path, not XDG
    home.file."Library/Application Support/Claude/claude_desktop_config.json" = {
      text = configJson;
    };
  };
}
