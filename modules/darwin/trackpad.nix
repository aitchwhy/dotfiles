# macOS trackpad configuration
# Comprehensive trackpad settings with granular gesture control
#
# This module configures THREE domains:
#   1. system.defaults.trackpad (high-level nix-darwin API)
#   2. com.apple.AppleMultitouchTrackpad (built-in trackpad)
#   3. com.apple.driver.AppleBluetoothMultitouch.trackpad (external trackpad)
#
# Gesture compatibility:
#   - 4-finger horizontal swipe: ENABLED by default (spaces/full-screen navigation)
#   - Other multi-finger gestures: DISABLED by default (for Swish window management)
{
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    mkEnableOption
    mkOption
    mkIf
    mkAfter
    types
    ;
  cfg = config.modules.darwin.trackpad;

  # Click pressure: 0=light, 1=medium, 2=firm
  clickThreshold =
    {
      light = 0;
      medium = 1;
      firm = 2;
    }
    .${
      cfg.clickPressure
    };

  # Gesture value: 0=disabled, 2=enabled
  gestureVal = enabled:
    if enabled
    then 2
    else 0;

  # Granular gesture values
  fourFingerHorizVal = gestureVal cfg.enableFourFingerHorizSwipe;
  swishConflictVal = gestureVal (!cfg.disableSwishConflicts);
in {
  options.modules.darwin.trackpad = {
    enable = mkEnableOption "macOS trackpad customization";

    tapToClick = mkOption {
      type = types.bool;
      default = true;
      description = "Enable tap-to-click (light tap = mouse click)";
    };

    twoFingerRightClick = mkOption {
      type = types.bool;
      default = true;
      description = "Two-finger tap for right-click/secondary click";
    };

    threeFingerDrag = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable three-finger drag.
        NOTE: Conflicts with Swish 3-finger gestures. Test before enabling.
      '';
    };

    clickPressure = mkOption {
      type = types.enum [
        "light"
        "medium"
        "firm"
      ];
      default = "medium";
      description = "Click pressure threshold for Force Touch trackpad";
    };

    naturalScrolling = mkOption {
      type = types.bool;
      default = true;
      description = "Natural (inverted) scrolling direction";
    };

    enableFourFingerHorizSwipe = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enable 4-finger horizontal swipe for switching spaces/full-screen apps.
        This gesture is independent of Swish and should generally be enabled.
      '';
    };

    disableSwishConflicts = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Disable gestures that conflict with Swish window management:
        - 3-finger horizontal/vertical swipes
        - 4-finger vertical swipe (Mission Control)
        - 4-finger pinch (Launchpad)
        - 5-finger pinch
        - 2-finger right edge swipe (Notification Center)

        When true: These gestures pass through to Swish.
        When false: macOS intercepts gestures for built-in features.
      '';
    };
  };

  config = mkIf cfg.enable {
    # High-level nix-darwin trackpad API
    system.defaults.trackpad = {
      Clicking = cfg.tapToClick;
      TrackpadRightClick = cfg.twoFingerRightClick;
      TrackpadThreeFingerDrag = cfg.threeFingerDrag;
      FirstClickThreshold = clickThreshold;
      SecondClickThreshold = clickThreshold;
      Dragging = false;
    };

    # Natural scrolling direction (shared with mouse in input-devices.nix)
    system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = cfg.naturalScrolling;

    # Built-in trackpad - comprehensive settings
    system.defaults.CustomUserPreferences."com.apple.AppleMultitouchTrackpad" = {
      # Basic click behavior
      Clicking = cfg.tapToClick;
      TrackpadRightClick = cfg.twoFingerRightClick;
      TrackpadThreeFingerDrag = cfg.threeFingerDrag;
      FirstClickThreshold = clickThreshold;
      SecondClickThreshold = clickThreshold;

      # Granular gesture control
      # 4-finger horizontal: controlled separately for spaces navigation
      TrackpadFourFingerHorizSwipeGesture = fourFingerHorizVal;

      # These gestures conflict with Swish - disable by default
      TrackpadFourFingerVertSwipeGesture = swishConflictVal;
      TrackpadFourFingerPinchGesture = swishConflictVal;
      TrackpadFiveFingerPinchGesture = swishConflictVal;
      TrackpadThreeFingerHorizSwipeGesture = swishConflictVal;
      TrackpadThreeFingerVertSwipeGesture = swishConflictVal;
      TrackpadTwoFingerFromRightEdgeSwipeGesture = swishConflictVal;

      # Keep useful gestures enabled (pinch-to-zoom, rotate)
      TrackpadTwoFingerDoubleTapGesture = 1; # Smart zoom
      TrackpadPinch = 1; # Pinch to zoom
      TrackpadRotate = 1; # Rotate gesture

      # Scrolling behavior
      TrackpadScroll = true;
      TrackpadMomentumScroll = true;
    };

    # Bluetooth/External trackpad - mirror all settings
    system.defaults.CustomUserPreferences."com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
      Clicking = cfg.tapToClick;
      TrackpadRightClick = cfg.twoFingerRightClick;
      TrackpadThreeFingerDrag = cfg.threeFingerDrag;
      FirstClickThreshold = clickThreshold;
      SecondClickThreshold = clickThreshold;

      # Granular gesture control (same as built-in)
      TrackpadFourFingerHorizSwipeGesture = fourFingerHorizVal;
      TrackpadFourFingerVertSwipeGesture = swishConflictVal;
      TrackpadFourFingerPinchGesture = swishConflictVal;
      TrackpadFiveFingerPinchGesture = swishConflictVal;
      TrackpadThreeFingerHorizSwipeGesture = swishConflictVal;
      TrackpadThreeFingerVertSwipeGesture = swishConflictVal;
      TrackpadTwoFingerFromRightEdgeSwipeGesture = swishConflictVal;

      # Keep useful gestures
      TrackpadTwoFingerDoubleTapGesture = 1;
      TrackpadPinch = 1;
      TrackpadRotate = 1;
    };

    # Activation script to force-apply gesture settings
    # Some settings require manual writes to take effect
    system.activationScripts.postActivation.text = lib.mkAfter ''
      echo ">>> Applying trackpad gesture settings..."

      # Built-in trackpad - 4-finger horizontal (spaces navigation)
      /usr/bin/defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerHorizSwipeGesture -int ${toString fourFingerHorizVal}

      # Built-in trackpad - Swish conflict gestures
      /usr/bin/defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerVertSwipeGesture -int ${toString swishConflictVal}
      /usr/bin/defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerPinchGesture -int ${toString swishConflictVal}
      /usr/bin/defaults write com.apple.AppleMultitouchTrackpad TrackpadFiveFingerPinchGesture -int ${toString swishConflictVal}
      /usr/bin/defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int ${toString swishConflictVal}
      /usr/bin/defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int ${toString swishConflictVal}

      # Bluetooth trackpad - same settings
      /usr/bin/defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerHorizSwipeGesture -int ${toString fourFingerHorizVal}
      /usr/bin/defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerVertSwipeGesture -int ${toString swishConflictVal}
      /usr/bin/defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerPinchGesture -int ${toString swishConflictVal}

      # Refresh preferences daemon
      /usr/bin/killall cfprefsd 2>/dev/null || true

      echo ">>> Trackpad: 4-finger horiz=${toString fourFingerHorizVal} (spaces), Swish conflicts=${toString swishConflictVal}"
      echo ">>> LOG OUT AND LOG BACK IN for full effect."
    '';
  };
}
