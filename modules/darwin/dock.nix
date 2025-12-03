# macOS Dock configuration
{ config, lib, ... }:

with lib;

{
  options.modules.darwin.dock = {
    enable = mkEnableOption "macOS Dock customization";
  };

  config = mkIf config.modules.darwin.dock.enable {
    system.defaults.dock = {
      # Position and behavior
      orientation = "left";
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.2;

      # Appearance
      tilesize = 48;
      launchanim = false;
      mineffect = "scale";
      show-process-indicators = true;
      show-recents = false;
      static-only = false;

      # Window management
      minimize-to-application = true;
      enable-spring-load-actions-on-all-items = true;
      expose-animation-duration = 0.1;
      expose-group-apps = true; # Group windows by application in Mission Control

      # Hot corners
      wvous-tl-corner = 2; # Mission Control
      wvous-tr-corner = 12; # Notification Center
      wvous-bl-corner = 3; # Application Windows
      wvous-br-corner = 4; # Desktop
    };
  };
}
