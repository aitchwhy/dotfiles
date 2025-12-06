# Claude Desktop MCP server configuration
# Uses /bin/sh wrapper to inject Nix PATH for Electron app compatibility
# Electron apps don't inherit shell PATH, so we must explicitly inject Nix paths
{
  config,
  lib,
  ...
}: let
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
  wrapNpxCommand = pkg: extraArgs: let
    argsString =
      if extraArgs == []
      then ""
      else " " + (concatStringsSep " " extraArgs);
  in {
    command = "/bin/sh";
    args = [
      "-c"
      "PATH=${pathString}:$PATH exec npx -y ${pkg}${argsString}"
    ];
  };

  mcpServers = {
    context7 = wrapNpxCommand "@upstash/context7-mcp" [];
    filesystem = wrapNpxCommand "@modelcontextprotocol/server-filesystem" [
      "$HOME/src"
      "$HOME/dotfiles"
      "$HOME/Obsidian"
      "$HOME/Documents"
      "$HOME/Downloads"
    ];
    memory = wrapNpxCommand "@modelcontextprotocol/server-memory" [];
    github = wrapNpxCommand "@modelcontextprotocol/server-github" [];
    "sequential-thinking" = wrapNpxCommand "@modelcontextprotocol/server-sequential-thinking" [];
  };

  configJson = builtins.toJSON {inherit mcpServers;};
in {
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
