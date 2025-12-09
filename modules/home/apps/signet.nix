# Signet - Code Quality & Generation Platform
# Provides the Signet CLI for generating formally consistent software projects.
#
# Features:
# - Centralized version management (from src/stack/versions.ts)
# - Code generation for monorepos, APIs, UIs, infrastructure
# - Hexagonal architecture enforcement
# - Effect-TS based with OXC + ast-grep AST analysis
# - Pulumi components for GCP infrastructure
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.modules.home.apps.signet = {
    enable = mkEnableOption "Signet (Code Quality & Generation Platform)";
  };

  config = mkIf config.modules.home.apps.signet.enable {
    # Signet CLI wrapper - runs TypeScript via Bun
    home.packages = [
      (pkgs.writeShellScriptBin "signet" ''
        # Signet CLI - Code Quality & Generation Platform
        # Usage: signet <command> [options]
        #   signet init <type> <name>     Initialize project
        #   signet gen <type> <name>      Generate workspace
        #   signet validate [path]        Validate against spec
        #   signet enforce [--fix]        Run enforcers
        #   signet reconcile [path]       Detect and fix code drift

        SIGNET_DIR="${config.home.homeDirectory}/dotfiles/config/signet"

        if [ ! -f "$SIGNET_DIR/src/cli.ts" ]; then
          echo "Error: Signet not initialized. Run 'bun install' in $SIGNET_DIR"
          exit 1
        fi

        exec ${pkgs.bun}/bin/bun run "$SIGNET_DIR/src/cli.ts" "$@"
      '')

      # Short alias 's' for quick access
      (pkgs.writeShellScriptBin "s" ''
        # s - Signet CLI shorthand
        # Delegates to signet command
        exec signet "$@"
      '')
    ];

    # Environment variables
    home.sessionVariables = {
      SIGNET_HOME = "${config.home.homeDirectory}/dotfiles/config/signet";
      SIGNET_VERSIONS = "${config.home.homeDirectory}/dotfiles/config/signet/versions.json";
    };

    # Generate versions.json from src/stack/versions.ts on activation
    home.activation.signetSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      SIGNET_DIR="${config.home.homeDirectory}/dotfiles/config/signet"
      VERSIONS_FILE="$SIGNET_DIR/versions.json"

      # Create signet directory if it doesn't exist
      $DRY_RUN_CMD mkdir -p "$SIGNET_DIR"

      # Install dependencies if package.json exists but node_modules doesn't
      if [ -f "$SIGNET_DIR/package.json" ] && [ ! -d "$SIGNET_DIR/node_modules" ]; then
        echo "Installing signet dependencies..."
        cd "$SIGNET_DIR" && ${pkgs.bun}/bin/bun install --frozen-lockfile 2>/dev/null || true
      fi

      # Generate versions.json from TypeScript STACK
      if [ -f "$SIGNET_DIR/src/stack/versions.ts" ]; then
        echo "Generating versions.json from src/stack/versions.ts..."
        cd "$SIGNET_DIR" && ${pkgs.bun}/bin/bun -e "
          import { versionsJson } from './src/stack/versions.ts';
          console.log(versionsJson);
        " > "$VERSIONS_FILE" 2>/dev/null || echo "Warning: Could not generate versions.json"
      fi
    '';
  };
}
