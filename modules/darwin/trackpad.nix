# macOS trackpad configuration
{ config, lib, ... }:

with lib;

{
  options.modules.darwin.trackpad = {
    enable = mkEnableOption "macOS trackpad customization";
  };

  config = mkIf config.modules.darwin.trackpad.enable {
    system.defaults.trackpad = {
      # Click behavior
      Clicking = true;
      TrackpadRightClick = true;

      # Gestures
      # Note: 3-finger drag disabled to allow Hammerspoon Swipe.spoon 4-finger gestures
      TrackpadThreeFingerDrag = false;

      # Click pressure (0=light, 1=medium, 2=firm)
      FirstClickThreshold = 1;   # was 0 (lightest) - medium pressure
      SecondClickThreshold = 1;  # was 0 (lightest) - medium pressure

      # Drag behavior
      Dragging = false;
    };
  };
}
