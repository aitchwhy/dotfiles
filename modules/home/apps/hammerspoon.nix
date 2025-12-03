# Hammerspoon automation configuration
{ config, lib, ... }:

with lib;

{
  options.modules.home.apps.hammerspoon = {
    enable = mkEnableOption "hammerspoon automation";
  };

  config = mkIf config.modules.home.apps.hammerspoon.enable {
    # Hammerspoon uses ~/.hammerspoon, not XDG
    home.file.".hammerspoon".source = ../../../config/hammerspoon;
  };
}
