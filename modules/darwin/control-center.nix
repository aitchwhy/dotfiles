# macOS Control Center menu bar configuration
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg = config.modules.darwin.controlCenter;
in
{
  options.modules.darwin.controlCenter = {
    enable = mkEnableOption "Control Center menu bar defaults";
  };

  config = mkIf cfg.enable {
    system.defaults.CustomUserPreferences."com.apple.controlcenter" = {
      # Menu bar item visibility
      # Items are hidden in menu bar but accessible via Control Center
      "NSStatusItem Visible Battery" = false;
      "NSStatusItem Visible Bluetooth" = false;
      "NSStatusItem Visible Sound" = false;
      "NSStatusItem Visible NowPlaying" = false;
      "NSStatusItem Visible Timer" = false;
      "NSStatusItem Visible Shortcuts" = false;

      # Control Center items (always visible via CC icon)
      "NSStatusItem Visible BentoBox" = true;
      "NSStatusItem VisibleCC AirDrop" = true;
      "NSStatusItem VisibleCC Clock" = true;
      "NSStatusItem VisibleCC FocusModes" = true;
      "NSStatusItem VisibleCC WiFi" = true;
      "NSStatusItem VisibleCC UserSwitcher" = true;

      # Remote Live Activities
      RemoteLiveActivitiesEnabled = true;
    };
  };
}
