# Bartender menu bar organizer
# https://www.macbartender.com/
#
# Bartender hides and shows menu bar items.
# Configuration is managed via the app's UI.
#
# NOTE: Bartender is installed via Homebrew (modules/homebrew.nix)
# This module is for tracking and potential future defaults management.
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
  cfg = config.modules.home.apps.bartender;
in
{
  options.modules.home.apps.bartender = {
    enable = mkEnableOption "Bartender menu bar organizer";

    showForUpdates = mkOption {
      type = types.bool;
      default = true;
      description = "Show hidden menu items when they have updates";
    };
  };

  config = mkIf cfg.enable {
    # Bartender preferences are stored in:
    # ~/Library/Preferences/com.surteesstudios.Bartender-4.plist
    #
    # Most settings require Bartender's UI to configure properly.
    # We can set a few basic defaults:
    targets.darwin.defaults."com.surteesstudios.Bartender-4" = {
      showForUpdates = cfg.showForUpdates;
    };
  };
}
