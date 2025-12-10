# nixbuild.net remote builder SSH configuration
{
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
in {
  options.modules.home.tools.nixbuild = {
    enable = mkEnableOption "nixbuild.net remote builder SSH config";

    identityFile = mkOption {
      type = types.str;
      default = "~/.ssh/nixbuild_ed25519";
      description = "Path to SSH private key for nixbuild.net";
    };

    region = mkOption {
      type = types.enum [
        "eu"
        "us"
      ];
      default = "eu";
      description = "nixbuild.net region (eu or us)";
    };
  };

  config = mkIf config.modules.home.tools.nixbuild.enable {
    programs.ssh = {
      enable = true;
      extraConfig = ''
        # nixbuild.net remote builder
        # Docs: https://docs.nixbuild.net/remote-builds/
        Host ${config.modules.home.tools.nixbuild.region}.nixbuild.net
          PubkeyAcceptedKeyTypes ssh-ed25519
          ServerAliveInterval 60
          IPQoS throughput
          IdentityFile ${config.modules.home.tools.nixbuild.identityFile}
      '';

      # nixbuild.net host key verification
      matchBlocks = {
        "nixbuild" = {
          host = "*.nixbuild.net";
          extraOptions = {
            PubkeyAcceptedKeyTypes = "ssh-ed25519";
          };
        };
      };
    };

    # Add known host for nixbuild.net
    home.file.".ssh/known_hosts.d/nixbuild".text = ''
      eu.nixbuild.net ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM
      us.nixbuild.net ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM
    '';
  };
}
