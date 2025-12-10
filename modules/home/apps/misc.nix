# Miscellaneous application configurations
# For tools without native home-manager support
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options.modules.home.apps.misc = {
    enable = mkEnableOption "miscellaneous app configs";
  };

  config = mkIf config.modules.home.apps.misc.enable {
    # Static configs (read-only symlinks)
    # Note: Cursor is handled separately in cursor.nix (macOS uses ~/Library/Application Support/)
    xdg.configFile = {
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

    # Note: Wispr Flow config is NOT managed here
    # It contains PII and is excluded from git (see config/SECURITY_NOTICE.md)
  };
}
