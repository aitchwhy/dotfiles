# Karabiner-Elements keyboard configuration
{ config, lib, ... }:

with lib;

{
  options.modules.home.apps.karabiner = {
    enable = mkEnableOption "karabiner keyboard remapping";
  };

  config = mkIf config.modules.home.apps.karabiner.enable {
    xdg.configFile."karabiner".source = ../../../config/karabiner;
  };
}
