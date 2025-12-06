# macOS input device configuration
# Mouse, external trackpad, and other pointing device settings
{ config, lib, ... }:

with lib;

let
  cfg = config.modules.darwin.inputDevices;
in
{
  options.modules.darwin.inputDevices = {
    enable = mkEnableOption "External input device configuration";

    mouseSpeed = mkOption {
      type = types.float;
      default = 1.0;
      description = ''
        Mouse tracking speed (0.0 - 3.0).
        Set to -1 to disable mouse acceleration entirely.
      '';
    };

    naturalScrolling = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Natural (inverted) scrolling direction.
        Affects both trackpad and mouse.
      '';
    };

    mouseButtonMode = mkOption {
      type = types.enum ["OneButton" "TwoButton"];
      default = "TwoButton";
      description = "Mouse button mode for Apple mice";
    };
  };

  config = mkIf cfg.enable {
    # Mouse scroll direction (shared with trackpad)
    system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = cfg.naturalScrolling;

    # Mouse speed/acceleration
    system.defaults.CustomUserPreferences.".GlobalPreferences" = {
      "com.apple.mouse.scaling" = cfg.mouseSpeed;
    };

    # Apple Magic Mouse settings
    system.defaults.CustomUserPreferences."com.apple.AppleMultitouchMouse" = {
      MouseButtonMode = cfg.mouseButtonMode;
    };

    # Bluetooth mouse settings
    system.defaults.CustomUserPreferences."com.apple.driver.AppleBluetoothMultitouch.mouse" = {
      MouseButtonMode = cfg.mouseButtonMode;
    };
  };
}
