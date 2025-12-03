# Zellij terminal multiplexer configuration
{ config, lib, ... }:

with lib;

{
  options.modules.home.tools.zellij = {
    enable = mkEnableOption "zellij terminal multiplexer";
  };

  config = mkIf config.modules.home.tools.zellij.enable {
    programs.zellij = {
      enable = true;
      enableZshIntegration = false; # Manual control preferred
      enableBashIntegration = false;
    };

    # Zellij uses KDL format, use xdg.configFile for full config
    xdg.configFile."zellij".source = ../../../config/zellij;
  };
}
