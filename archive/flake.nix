{
  description = "Hank's Nix Configuration";

  inputs = {
    # Package sets
    nixpkgs.url = "github:nixos/nixpkgs/23.11";

    # Environment/system management
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix formatter
    alejandra = {
      url = "github:kamadorueda/alejandra/3.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Optional: Add flake-utils for better multi-platform support
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs @ { self, nixpkgs, darwin, home-manager, flake-utils, ... }:
    let
      # System settings for each host
      hosts = {
        "hank-mbp" = {
          system = "aarch64-darwin";
          username = "hank";
          useremail = "hank.lee.qed@gmail.com";
        };

        "hank-mstio" = {
          system = "aarch64-darwin";
          username = "hank";
          useremail = "hank.lee.qed@gmail.com";
        };
      };

      # Function to create Darwin configuration for a host
      mkDarwinConfig = hostname: hostConfig:
        darwin.lib.darwinSystem {
          system = hostConfig.system;
          specialArgs = {
            inherit (hostConfig) username useremail;
            inherit hostname;
          } // inputs;

          modules = [
            # Core nix configuration
            ./modules/nix-core.nix

            # System configuration
            ./modules/system.nix

            # Host-specific users
            ./modules/host-users.nix

            # Apps and packages
            ./modules/apps.nix

            # Home Manager configuration
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit (hostConfig) username useremail;
                  inherit hostname;
                };
                users.${hostConfig.username} = import ./home;
              };
            }
          ];
        };
    in
    {
      # Generate configurations for all hosts
      darwinConfigurations = builtins.mapAttrs mkDarwinConfig hosts;

      # Formatter
      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;

      # Add checks for each host configuration
      checks.aarch64-darwin = builtins.mapAttrs (name: config: config.system.build.toplevel)
        self.darwinConfigurations;
    };
}
