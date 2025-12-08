# Universal Project Factory
# Provides the FCS (Factory Control System) CLI for generating
# formally consistent software projects.
#
# Features:
# - Centralized version management (from lib/versions.nix)
# - Code generation for monorepos, APIs, UIs, infrastructure
# - Hexagonal architecture enforcement
# - Unified observability (process-compose, vscode debug)
{
  config,
  lib,
  pkgs,
  versions,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  versionsJson = builtins.toJSON versions;
in
{
  options.modules.home.apps.factory = {
    enable = mkEnableOption "Universal Project Factory (FCS CLI)";
  };

  config = mkIf config.modules.home.apps.factory.enable {
    # FCS CLI wrapper - runs TypeScript via Bun
    home.packages = [
      (pkgs.writeShellScriptBin "fcs" ''
        # Universal Project Factory CLI
        # Usage: fcs <command> [options]
        #   fcs init <type> <name>     Initialize project
        #   fcs gen <type> <name>      Generate workspace
        #   fcs validate [path]        Validate against spec
        #   fcs enforce [--fix]        Run enforcers

        FACTORY_DIR="${config.home.homeDirectory}/dotfiles/config/factory"

        if [ ! -f "$FACTORY_DIR/src/cli.ts" ]; then
          echo "Error: Factory not initialized. Run 'bun install' in $FACTORY_DIR"
          exit 1
        fi

        exec ${pkgs.bun}/bin/bun run "$FACTORY_DIR/src/cli.ts" "$@"
      '')
    ];

    # Environment variables
    home.sessionVariables = {
      FCS_HOME = "${config.home.homeDirectory}/dotfiles/config/factory";
      FCS_VERSIONS = "${config.home.homeDirectory}/dotfiles/config/factory/versions.json";
    };

    # Generate versions.json from versions.nix on activation
    home.activation.factorySetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      FACTORY_DIR="${config.home.homeDirectory}/dotfiles/config/factory"
      VERSIONS_FILE="$FACTORY_DIR/versions.json"

      # Create factory directory if it doesn't exist
      $DRY_RUN_CMD mkdir -p "$FACTORY_DIR"

      # Write versions.json from Nix-evaluated versions
      cat > "$VERSIONS_FILE" << 'EOF'
${versionsJson}
EOF

      echo "Factory versions.json generated from lib/versions.nix"

      # Install dependencies if package.json exists but node_modules doesn't
      if [ -f "$FACTORY_DIR/package.json" ] && [ ! -d "$FACTORY_DIR/node_modules" ]; then
        echo "Installing factory dependencies..."
        cd "$FACTORY_DIR" && ${pkgs.bun}/bin/bun install --frozen-lockfile 2>/dev/null || true
      fi
    '';
  };
}
