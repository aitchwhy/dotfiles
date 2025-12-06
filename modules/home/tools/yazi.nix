# Yazi file manager configuration
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.modules.home.tools.yazi = {
    enable = mkEnableOption "yazi file manager";
  };

  config = mkIf config.modules.home.tools.yazi.enable {
    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };

    # Yazi's config is complex (Lua + TOML), use xdg.configFile
    xdg.configFile."yazi".source = ../../../config/yazi;
  };
}
