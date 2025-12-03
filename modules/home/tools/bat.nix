# Bat (cat replacement) configuration
{ config, lib, ... }:

with lib;

{
  options.modules.home.tools.bat = {
    enable = mkEnableOption "bat syntax highlighting";
  };

  config = mkIf config.modules.home.tools.bat.enable {
    programs.bat = {
      enable = true;
      config = {
        theme = "TwoDark";
        pager = "less -FR";
        style = "numbers,changes,header";
      };
    };
  };
}
