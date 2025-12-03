# AeroSpace tiling window manager configuration
{ config, lib, ... }:

with lib;

{
  options.modules.home.apps.aerospace = {
    enable = mkEnableOption "aerospace window manager";
  };

  config = mkIf config.modules.home.apps.aerospace.enable {
    xdg.configFile."aerospace".source = ../../../config/aerospace;
  };
}
