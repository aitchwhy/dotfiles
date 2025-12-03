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
      TrackpadThreeFingerDrag = true;

      # Click pressure
      FirstClickThreshold = 0;
      SecondClickThreshold = 0;

      # Drag behavior
      Dragging = false;
    };
  };
}
