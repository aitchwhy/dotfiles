# Home Manager package aggregator
# Consolidates user packages from users/hank.nix and users/hank-linux.nix
# into platform-aware modules to eliminate 90% duplication.
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkOption
    types
    ;
in
{
  imports = [
    ./common.nix
    ./darwin.nix
    ./linux.nix
  ];

  options.modules.home.packages = {
    enable = mkEnableOption "user packages";

    enableCloudPlatforms = mkOption {
      type = types.bool;
      default = true;
      description = "Enable cloud platform CLIs (AWS, Azure, GCP, Fly)";
    };

    enableKubernetes = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Kubernetes tools (kubectl, helm, k9s)";
    };

    enableLanguages = mkOption {
      type = types.bool;
      default = true;
      description = "Enable programming language toolchains";
    };

    enableDatabases = mkOption {
      type = types.bool;
      default = true;
      description = "Enable database clients (PostgreSQL, MongoDB, Redis)";
    };

    enableNixTools = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Nix development tools (cachix, devenv, nixd)";
    };
  };

  config = {
    # Enable packages by default
    modules.home.packages.enable = mkDefault true;
  };
}
