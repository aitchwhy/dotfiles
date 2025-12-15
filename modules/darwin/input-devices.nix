# macOS input device configuration
# Mouse, trackpad, and other pointing device settings
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
  cfg = config.modules.darwin.inputDevices;

  # Click threshold: 0 = Light, 1 = Medium, 2 = Firm
  clickThresholdValue = {
    "light" = 0;
    "medium" = 1;
    "firm" = 2;
  };
in
{
  options.modules.darwin.inputDevices = {
    enable = mkEnableOption "External input device configuration";

    # Mouse settings
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
      type = types.enum [
        "OneButton"
        "TwoButton"
      ];
      default = "TwoButton";
      description = "Mouse button mode for Apple mice";
    };

    # Trackpad settings
    trackpad = {
      tapToClick = mkOption {
        type = types.bool;
        default = true;
        description = "Enable tap to click on trackpad";
      };

      clickThreshold = mkOption {
        type = types.enum [
          "light"
          "medium"
          "firm"
        ];
        default = "firm";
        description = ''
          Click sensitivity threshold.
          - light: Very sensitive, easy to trigger
          - medium: Default macOS setting
          - firm: Requires deliberate press, prevents phantom clicks
        '';
      };

      twoFingerRightClick = mkOption {
        type = types.bool;
        default = true;
        description = "Two-finger tap for right click";
      };

      threeFingerDrag = mkOption {
        type = types.bool;
        default = false;
        description = "Three-finger drag (can cause accidental triggers)";
      };

      palmRejection = mkOption {
        type = types.bool;
        default = true;
        description = "Ignore accidental trackpad input from palm";
      };

      hapticFeedback = mkOption {
        type = types.bool;
        default = true;
        description = "Enable haptic feedback for Force Touch trackpad";
      };
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

    # Built-in trackpad settings
    system.defaults.trackpad = {
      # Tap to click
      Clicking = cfg.trackpad.tapToClick;
      # Two-finger right click
      TrackpadRightClick = cfg.trackpad.twoFingerRightClick;
      # Three-finger drag (accessibility feature, can cause phantom clicks)
      TrackpadThreeFingerDrag = cfg.trackpad.threeFingerDrag;
    };

    # Advanced trackpad settings (both built-in and Bluetooth)
    system.defaults.CustomUserPreferences."com.apple.AppleMultitouchTrackpad" = {
      # Click sensitivity: 0=Light, 1=Medium, 2=Firm
      # Firm prevents phantom clicks from accidental touches
      FirstClickThreshold = clickThresholdValue.${cfg.trackpad.clickThreshold};
      SecondClickThreshold = clickThresholdValue.${cfg.trackpad.clickThreshold};
      # Palm rejection - ignore accidental input
      TrackpadHandResting = cfg.trackpad.palmRejection;
      # Haptic feedback
      ActuateDetents = cfg.trackpad.hapticFeedback;
      # Tap to click (mirror of system.defaults.trackpad.Clicking)
      Clicking = cfg.trackpad.tapToClick;
      # Three-finger drag
      TrackpadThreeFingerDrag = cfg.trackpad.threeFingerDrag;
    };

    # Bluetooth trackpad settings (same as built-in)
    system.defaults.CustomUserPreferences."com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
      FirstClickThreshold = clickThresholdValue.${cfg.trackpad.clickThreshold};
      SecondClickThreshold = clickThresholdValue.${cfg.trackpad.clickThreshold};
      TrackpadHandResting = cfg.trackpad.palmRejection;
      Clicking = cfg.trackpad.tapToClick;
      TrackpadThreeFingerDrag = cfg.trackpad.threeFingerDrag;
    };
  };
}
