# Google Chrome browser configuration
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.modules.home.apps.chrome;
in
{
  options.modules.home.apps.chrome = {
    enable = mkEnableOption "Google Chrome settings";

    disableSwipeNavigation = mkOption {
      type = types.bool;
      default = true;
      description = "Disable swipe navigation (prevents accidental back/forward)";
    };
  };

  config = mkIf cfg.enable {
    targets.darwin.defaults."com.google.Chrome" = {
      # Swipe navigation
      AppleEnableSwipeNavigateWithScrolls = !cfg.disableSwipeNavigation;

      # External protocol dialogs - don't ask every time
      ExternalProtocolDialogShowAlwaysOpenCheckbox = true;
    };
  };
}
