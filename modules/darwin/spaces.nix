# macOS Spaces / Mission Control configuration
# Controls space behavior, auto-rearranging, and multi-display handling
{ config, lib, ... }:

with lib;

let
  cfg = config.modules.darwin.spaces;
in
{
  options.modules.darwin.spaces = {
    enable = mkEnableOption "macOS Spaces/Mission Control configuration";

    autoRearrange = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Automatically rearrange Spaces based on most recent use.
        Disable for predictable, stable Space ordering.
      '';
    };

    separateSpacesPerDisplay = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Each display has its own set of Spaces.
        When false, spaces span all displays.
      '';
    };

    switchToSpaceWithApp = mkOption {
      type = types.bool;
      default = true;
      description = "When switching to an app, switch to the Space where its windows are";
    };

    groupWindowsByApp = mkOption {
      type = types.bool;
      default = false;
      description = "Group windows by application in Mission Control";
    };
  };

  config = mkIf cfg.enable {
    # Dock settings for spaces
    system.defaults.dock = {
      mru-spaces = cfg.autoRearrange;
      # NOTE: expose-group-apps is set in dock.nix to avoid conflicts
    };

    # Spaces-specific settings
    system.defaults.CustomUserPreferences."com.apple.spaces" = {
      "spans-displays" =
        if cfg.separateSpacesPerDisplay
        then 0
        else 1;
    };

    # Global space switching behavior
    system.defaults.CustomUserPreferences.".GlobalPreferences" = {
      AppleSpacesSwitchOnActivate = cfg.switchToSpaceWithApp;
    };
  };
}
