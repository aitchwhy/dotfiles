# Swish trackpad window management
# https://highlyopinionated.co/swish/
#
# Swish enables trackpad gestures for window management:
#   - Swipe left/right: Snap to half
#   - Swipe up: Maximize
#   - Swipe down: Minimize
#   - Pinch in/out: Tile or fill
#
# NOTE: Requires system trackpad gestures to be DISABLED
# (see modules/darwin/trackpad.nix disableSystemGestures option)
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
  cfg = config.modules.home.apps.swish;
in
{
  options.modules.home.apps.swish = {
    enable = mkEnableOption "Swish trackpad window management";

    swipeSensitivity = mkOption {
      type = types.ints.between 1 5;
      default = 3;
      description = "Swipe sensitivity (1=light, 5=firm). Default 3.";
    };
  };

  config = mkIf cfg.enable {
    # Swish stores its preferences in ~/Library/Preferences/co.highlyopinionated.swish.plist
    # Basic settings can be configured via defaults
    targets.darwin.defaults."co.highlyopinionated.swish" = {
      SUEnableAutomaticChecks = true;
      swipeSensitivity = cfg.swipeSensitivity;
    };
  };
}
