# Claude Desktop MCP Runtime Configuration
# Automatically patches MCP extensions to use bun instead of node
# Enforces configuration declaratively - survives Claude Desktop updates
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.modules.home.apps.claude-desktop;
in
{
  options.modules.home.apps.claude-desktop = {
    enable = mkEnableOption "Claude Desktop MCP runtime enforcement";

    mcpRuntime = mkOption {
      type = types.enum [
        "bun"
        "node"
      ];
      default = "node";
      description = "Runtime for MCP server execution";
    };
  };

  config = mkIf cfg.enable {
    # Ensure runtime is available
    home.packages = if cfg.mcpRuntime == "bun" then [ pkgs.bun ] else [ pkgs.nodejs_25 ];

    # Declarative MCP extension patching (runs on every darwin-rebuild/home-manager switch)
    # Survives Claude Desktop updates by re-applying patches on each activation
    home.activation.patchClaudeMcpExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      RUNTIME="${cfg.mcpRuntime}"
      EXT_DIR="$HOME/Library/Application Support/Claude/Claude Extensions"

      if [ ! -d "$EXT_DIR" ]; then
        echo "Claude extensions directory not found - skipping MCP runtime patch"
        exit 0
      fi

      echo "Patching Claude MCP extensions to use: $RUNTIME"

      # Patch manifest.json files (idempotent - patches both "bun" and "node" to target runtime)
      # Use macOS system find and sed (fd alias conflicts with find command)
      /usr/bin/find "$EXT_DIR" -name "manifest.json" -type f | while read -r file; do
        sed -i.bak "s/\"command\": \"bun\"/\"command\": \"$RUNTIME\"/g" "$file" && rm -f "$file.bak"
        sed -i.bak "s/\"command\": \"node\"/\"command\": \"$RUNTIME\"/g" "$file" && rm -f "$file.bak"
      done

      # Patch .js shebangs (idempotent - patches both bun and node shebangs)
      /usr/bin/find "$EXT_DIR" -name "*.js" -type f | while read -r file; do
        sed -i.bak "s|#!/usr/bin/env bun|#!/usr/bin/env $RUNTIME|g" "$file" && rm -f "$file.bak"
        sed -i.bak "s|#!/usr/bin/env node|#!/usr/bin/env $RUNTIME|g" "$file" && rm -f "$file.bak"
      done

      echo "Claude MCP runtime enforcement complete"
    '';
  };
}
