# Docker client configuration (declarative)
# Manages ~/.docker/config.json
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.home.tools.docker;
in
{
  options.modules.home.tools.docker = {
    enable = mkEnableOption "Docker client configuration";
  };

  config = mkIf cfg.enable {
    home.file.".docker/config.json".text = builtins.toJSON {
      auths = { };
      credsStore = "osxkeychain";
      cliPluginsExtraDirs = [
        "/opt/homebrew/lib/docker/cli-plugins"
      ];
    };

    home.packages = with pkgs; [
      docker-client
    ];
  };
}
