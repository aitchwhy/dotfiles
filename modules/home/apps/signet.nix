# Signet - Code Quality & Generation Platform
# Provides the Signet CLI for generating formally consistent software projects.
#
# Features:
# - Centralized version management (from lib/versions.nix)
# - Code generation for monorepos, APIs, UIs, infrastructure
# - Hexagonal architecture enforcement
# - Effect-TS based with OXC + ast-grep AST analysis
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
    ];

    # Environment variables
    home.sessionVariables = {
      SIGNET_HOME = "${config.home.homeDirectory}/dotfiles/config/signet";
      SIGNET_VERSIONS = "${config.home.homeDirectory}/dotfiles/config/signet/versions.json";
    };

    # Generate versions.json from versions.nix on activation
    home.activation.signetSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      SIGNET_DIR="${config.home.homeDirectory}/dotfiles/config/signet"
      VERSIONS_FILE="$SIGNET_DIR/versions.json"

      # Create signet directory if it doesn't exist
      $DRY_RUN_CMD mkdir -p "$SIGNET_DIR"

      # Write versions.json from Nix-evaluated versions
      cat > "$VERSIONS_FILE" << 'EOF'
${versionsJson}
EOF

      echo "Signet versions.json generated from lib/versions.nix"

      # Install dependencies if package.json exists but node_modules doesn't
      if [ -f "$SIGNET_DIR/package.json" ] && [ ! -d "$SIGNET_DIR/node_modules" ]; then
        echo "Installing signet dependencies..."
        cd "$SIGNET_DIR" && ${pkgs.bun}/bin/bun install --frozen-lockfile 2>/dev/null || true
      fi
    '';
  };
}
