# Colmena deployment configuration
# Docs: https://colmena.cli.rs/unstable/
#
# Usage (use colmena from flake input, not nixpkgs - version compatibility):
#   nix run github:zhaofengli/colmena -- apply --on cloud
#   nix run github:zhaofengli/colmena -- eval
#   nix run github:zhaofengli/colmena -- apply --on cloud --evaluator streaming
{
  self,
  inputs,
  ...
}:
{
  # Use colmena.lib.makeHive for proper flake integration (silences "unknown output" warning)
  flake.colmenaHive = inputs.colmena.lib.makeHive {
    meta = {
      # Use nixpkgs from flake for consistency
      nixpkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
      };

      # Pass inputs and self to all hosts
      specialArgs = { inherit inputs self; };

      # Optional: Speed up evaluation with this
      # machinesFile = "/etc/nix/machines";
    };

    # Default configuration applied to all hosts
    defaults = {
      # Common settings for all deployed hosts
      deployment = {
        buildOnTarget = false; # Build locally or via nixbuild.net
        replaceUnknownProfiles = true;
      };
    };

    # Cloud VM (Google Compute Engine)
    cloud = {
      deployment = {
        # Tailscale hostname - requires VPN connection
        targetHost = "cloud";
        targetUser = "hank";

        # Tags for filtering deployments
        tags = [
          "cloud"
          "gcp"
          "production"
        ];

        # Use switch-then-reboot for atomic updates
        # Options: switch, boot, test, dry-activate
        targetPort = 22;
      };

      # Import the existing NixOS configuration
      imports = [
        inputs.disko.nixosModules.disko
        inputs.sops-nix.nixosModules.sops
        ../hosts/cloud/configuration.nix
        ../modules/nixpkgs.nix
        ../modules/nixos

        # Home Manager integration
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs self; };
            users.hank = import ../users/hank-linux.nix;
            backupFileExtension = "backup";
          };
        }
      ];
    };

    # Future hosts can be added here:
    # staging = { ... }: { ... };
    # gpu = { ... }: { ... };
  };
}
