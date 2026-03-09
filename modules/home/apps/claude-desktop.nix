# Claude Desktop MCP Runtime Configuration
# Patches MCP extensions to use absolute bun path (Electron apps have restricted PATH)
# Enforces configuration declaratively - survives Claude Desktop updates
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg = config.modules.home.apps.claude-desktop;
in
{
  options.modules.home.apps.claude-desktop = {
    enable = mkEnableOption "Claude Desktop MCP runtime enforcement";
  };

  config = mkIf cfg.enable {
    # Declarative MCP extension patching (runs on every darwin-rebuild/home-manager switch)
    # Survives Claude Desktop updates by re-applying patches on each activation
    home.activation.patchClaudeMcpExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      BUN_PATH="/etc/profiles/per-user/${config.home.username}/bin/bun"
      EXT_DIR="$HOME/Library/Application Support/Claude/Claude Extensions"

      if [ ! -d "$EXT_DIR" ]; then
        echo "Claude extensions directory not found - skipping MCP runtime patch"
        exit 0
      fi

      if [ ! -x "$BUN_PATH" ]; then
        echo "ERROR: bun not found at $BUN_PATH - cannot patch MCP extensions"
        exit 1
      fi

      echo "Patching Claude MCP extensions to use: $BUN_PATH"

      # Patch manifest.json command fields to absolute bun path (handles any previous value)
      /usr/bin/find "$EXT_DIR" -name "manifest.json" -type f | while read -r file; do
        sed -i.bak 's|"command": "[^"]*"|"command": "'"$BUN_PATH"'"|g' "$file" && rm -f "$file.bak"
      done

      # Patch .js shebangs to absolute bun path
      /usr/bin/find "$EXT_DIR" -name "*.js" -type f | while read -r file; do
        sed -i.bak 's|#!/usr/bin/env bun|#!'"$BUN_PATH"'|g' "$file" && rm -f "$file.bak"
        sed -i.bak 's|#!/usr/bin/env node|#!'"$BUN_PATH"'|g' "$file" && rm -f "$file.bak"
      done

      echo "Claude MCP runtime enforcement complete (absolute path: $BUN_PATH)"
    '';
  };
}
