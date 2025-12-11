# Homerow configuration
# Keyboard shortcuts for every button on screen
# https://www.homerow.app/
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.modules.home.apps.homerow = {
    enable = mkEnableOption "Homerow keyboard navigation";
  };

  config = mkIf config.modules.home.apps.homerow.enable {
    # Homerow preferences via defaults
    # Bundle ID: com.superultra.Homerow
    targets.darwin.defaults."com.superultra.Homerow" = {
      # Click on screen with letter preview: Opt+Shift+Space
      # Scroll mode: Opt+Shift+S
      # Note: Homerow uses key code integers for modifiers
      # Shift = 131072, Option = 524288, Shift+Option = 655360
      # Space = 49, S = 1
      clickShortcutKeyCode = 49; # Space
      clickShortcutModifiers = 655360; # Opt+Shift
      scrollShortcutKeyCode = 1; # S
      scrollShortcutModifiers = 655360; # Opt+Shift
    };
  };
}
