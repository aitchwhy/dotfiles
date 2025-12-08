# Miscellaneous application configurations
# For tools without native home-manager support
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.modules.home.apps.misc = {
    enable = mkEnableOption "miscellaneous app configs";
  };

  config = mkIf config.modules.home.apps.misc.enable {
    # Static configs (read-only symlinks)
    # Note: Cursor is handled separately in cursor.nix (macOS uses ~/Library/Application Support/)
    xdg.configFile = {
      "aider".source = ../../../config/aider;
      "lazydocker".source = ../../../config/lazydocker;
      "httpie".source = ../../../config/httpie;
      "just".source = ../../../config/just;
      "glow".source = ../../../config/glow;
      "repomix".source = ../../../config/repomix;
      "tree-sitter".source = ../../../config/tree-sitter;
      "hazel".source = ../../../config/hazel;
    };

    # CLI scripts (executable symlinks to ~/.local/bin)
    home.file.".local/bin/rx" = {
      source = ../../../config/scripts/rx;
      executable = true;
    };

    # Wispr Flow config - COPY instead of symlink
    # Wispr Flow needs to write vocabulary/dictionary at runtime
    # Base config is tracked in git, runtime changes are preserved
    home.activation.wisprFlowConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      CONFIG_DIR="$HOME/Library/Application Support/Wispr Flow"
      CONFIG_FILE="$CONFIG_DIR/config.json"
      SOURCE_FILE="${../../../config/wispr-flow/config.json}"

      # Create directory if needed
      $DRY_RUN_CMD mkdir -p "$CONFIG_DIR"

      # Remove symlink if it exists (transition from old home-manager setup)
      if [ -L "$CONFIG_FILE" ]; then
        $DRY_RUN_CMD rm "$CONFIG_FILE"
        echo "Removed old Wispr Flow symlink"
      fi

      # Only copy if target doesn't exist (preserve user's runtime changes)
      if [ ! -f "$CONFIG_FILE" ]; then
        $DRY_RUN_CMD cp "$SOURCE_FILE" "$CONFIG_FILE"
        $DRY_RUN_CMD chmod 644 "$CONFIG_FILE"
        echo "Wispr Flow config initialized from dotfiles"
      fi
    '';
  };
}
