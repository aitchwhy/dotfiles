# macOS trackpad configuration
# Comprehensive trackpad settings for Swish compatibility
#
# CRITICAL: System gestures MUST be disabled for Swish to intercept trackpad input.
# This module configures THREE domains:
#   1. system.defaults.trackpad (high-level nix-darwin API)
#   2. com.apple.AppleMultitouchTrackpad (built-in trackpad)
#   3. com.apple.driver.AppleBluetoothMultitouch.trackpad (external trackpad)
#
# TEST: After applying, 4-finger gestures should NOT trigger Mission Control/Launchpad
{ config, lib, ... }:

with lib;

let
  cfg = config.modules.darwin.trackpad;

  # Click pressure: 0=light, 1=medium, 2=firm
  clickThreshold = {
    light = 0;
    medium = 1;
    firm = 2;
  }.${cfg.clickPressure};

  # Gesture value: 0=disabled, 2=enabled
  gestureVal = enabled:
    if enabled
    then 2
    else 0;
in
{
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
        NOTE: Conflicts with some Swish gestures. Test before enabling.
      '';
    };

    clickPressure = mkOption {
      type = types.enum ["light" "medium" "firm"];
      default = "medium";
      description = "Click pressure threshold for Force Touch trackpad";
    };

    naturalScrolling = mkOption {
      type = types.bool;
      default = true;
      description = "Natural (inverted) scrolling direction";
    };

    disableSystemGestures = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Disable macOS system gestures (Mission Control, Launchpad, App Exposé).
        REQUIRED for Swish to intercept trackpad gestures.
        When true: 4-finger gestures pass through to Swish.
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

      # CRITICAL: System gesture settings for Swish compatibility
      # All set to 0 when disableSystemGestures = true
      TrackpadFourFingerHorizSwipeGesture = gestureVal (!cfg.disableSystemGestures);
      TrackpadFourFingerVertSwipeGesture = gestureVal (!cfg.disableSystemGestures);
      TrackpadFourFingerPinchGesture = gestureVal (!cfg.disableSystemGestures);
      TrackpadFiveFingerPinchGesture = gestureVal (!cfg.disableSystemGestures);
      TrackpadThreeFingerHorizSwipeGesture = gestureVal (!cfg.disableSystemGestures);
      TrackpadThreeFingerVertSwipeGesture = gestureVal (!cfg.disableSystemGestures);
      TrackpadTwoFingerFromRightEdgeSwipeGesture = gestureVal (!cfg.disableSystemGestures);

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

      # System gesture disabling
      TrackpadFourFingerHorizSwipeGesture = gestureVal (!cfg.disableSystemGestures);
      TrackpadFourFingerVertSwipeGesture = gestureVal (!cfg.disableSystemGestures);
      TrackpadFourFingerPinchGesture = gestureVal (!cfg.disableSystemGestures);
      TrackpadFiveFingerPinchGesture = gestureVal (!cfg.disableSystemGestures);
      TrackpadThreeFingerHorizSwipeGesture = gestureVal (!cfg.disableSystemGestures);
      TrackpadThreeFingerVertSwipeGesture = gestureVal (!cfg.disableSystemGestures);
      TrackpadTwoFingerFromRightEdgeSwipeGesture = gestureVal (!cfg.disableSystemGestures);

      # Keep useful gestures
      TrackpadTwoFingerDoubleTapGesture = 1;
      TrackpadPinch = 1;
      TrackpadRotate = 1;
    };

    # Activation script to force-apply gesture settings
    # Some settings require manual writes to take effect
    system.activationScripts.postActivation.text = lib.mkAfter ''
      echo ">>> Applying trackpad gesture settings for Swish compatibility..."

      # Built-in trackpad
      /usr/bin/defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerPinchGesture -int ${toString (gestureVal (!cfg.disableSystemGestures))}
      /usr/bin/defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerVertSwipeGesture -int ${toString (gestureVal (!cfg.disableSystemGestures))}
      /usr/bin/defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerHorizSwipeGesture -int ${toString (gestureVal (!cfg.disableSystemGestures))}
      /usr/bin/defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int ${toString (gestureVal (!cfg.disableSystemGestures))}
      /usr/bin/defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int ${toString (gestureVal (!cfg.disableSystemGestures))}
      /usr/bin/defaults write com.apple.AppleMultitouchTrackpad TrackpadFiveFingerPinchGesture -int ${toString (gestureVal (!cfg.disableSystemGestures))}

      # Bluetooth trackpad
      /usr/bin/defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerPinchGesture -int ${toString (gestureVal (!cfg.disableSystemGestures))}
      /usr/bin/defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerVertSwipeGesture -int ${toString (gestureVal (!cfg.disableSystemGestures))}
      /usr/bin/defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerHorizSwipeGesture -int ${toString (gestureVal (!cfg.disableSystemGestures))}

      # Refresh preferences daemon
      /usr/bin/killall cfprefsd 2>/dev/null || true

      echo ">>> Trackpad settings applied. LOG OUT AND LOG BACK IN for full effect."
    '';
  };
}
