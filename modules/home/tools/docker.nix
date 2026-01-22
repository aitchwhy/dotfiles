# Docker client configuration (declarative)
# OrbStack manages Docker context automatically - no DOCKER_HOST needed
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
    # OrbStack automatically sets the Docker context via socket at /var/run/docker.sock
    # No DOCKER_HOST override needed - Docker CLI provided by Homebrew
  };
}
