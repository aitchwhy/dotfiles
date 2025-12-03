# Claude Desktop MCP server configuration
# Deploys claude_desktop_config.json to ~/Library/Application Support/Claude/
{ config, lib, ... }:

with lib;

{
  options.modules.home.apps.claude = {
    enable = mkEnableOption "Claude Desktop MCP servers";
  };

  config = mkIf config.modules.home.apps.claude.enable {
    # Claude Desktop stores config in ~/Library/Application Support/Claude/
    # This is a macOS-specific path, not XDG
    home.file."Library/Application Support/Claude/claude_desktop_config.json".source =
      ../../../config/claude/claude_desktop_config.json;
  };
}
