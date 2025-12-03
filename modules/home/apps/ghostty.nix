# Ghostty terminal configuration
{ config, lib, ... }:

with lib;

{
  options.modules.home.apps.ghostty = {
    enable = mkEnableOption "ghostty terminal";
  };

  config = mkIf config.modules.home.apps.ghostty.enable {
    xdg.configFile."ghostty".source = ../../../config/ghostty;
  };
}
