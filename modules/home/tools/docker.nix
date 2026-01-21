# Docker client configuration (declarative)
# Sets DOCKER_HOST to use Colima socket
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
    # Set DOCKER_HOST to Colima socket (avoids config.json context conflicts)
    # Docker CLI provided by Homebrew (alongside Colima) for version compatibility
    home.sessionVariables = {
      DOCKER_HOST = "unix:///Users/${config.home.username}/.colima/default/docker.sock";
    };
  };
}
