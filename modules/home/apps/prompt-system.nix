# Prompt-as-Code System
# Generates SKILL.md and .mdc files from TypeScript definitions
# on darwin-rebuild switch.
#
# Source: config/system/
# Output:
#   - Skills → config/claude-code/skills/*/SKILL.md
#   - Cursor rules → .cursor/rules/*.mdc
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
  options.modules.home.apps.promptSystem = {
    enable = mkEnableOption "Prompt-as-Code system (TypeScript → SKILL.md + .mdc)";
  };

  config = mkIf config.modules.home.apps.promptSystem.enable {
    # Build SKILL.md and .mdc files from TypeScript definitions on activation
    home.activation.promptSystemBuild = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      SYSTEM_DIR="${config.home.homeDirectory}/dotfiles/config/system"

      if [ ! -f "$SYSTEM_DIR/package.json" ]; then
        echo "Prompt system not found at $SYSTEM_DIR"
        exit 0
      fi

      # Install dependencies if node_modules doesn't exist
      if [ ! -d "$SYSTEM_DIR/node_modules" ]; then
        echo "Installing prompt system dependencies..."
        cd "$SYSTEM_DIR" && ${pkgs.bun}/bin/bun install --frozen-lockfile 2>/dev/null || true
      fi

      # Run build to generate SKILL.md and .mdc files
      echo "Building prompt system (TypeScript → SKILL.md + .mdc)..."
      cd "$SYSTEM_DIR" && ${pkgs.bun}/bin/bun run src/build.ts

      echo "Prompt system build complete"
    '';
  };
}
