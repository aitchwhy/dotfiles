{
  description = "Hank's Darwin System";

  inputs = {
    # Package sets
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    
    # Environment/system management
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, darwin, home-manager, ... }:
    let
      # Configuration for each host
      hosts = {
        # MacBook Pro configuration
        "hank-mbp" = {
          system = "aarch64-darwin";
          username = "hank";
          useremail = "hank.lee.qed@gmail.com";
        };
        
        # Mac Studio configuration
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
            # Core system configuration
            ./modules/nix-core.nix
            ./modules/system.nix
            ./modules/host-users.nix
            ./modules/apps.nix
            ./modules/homebrew-mirror.nix

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

    in {
      # Generate configurations for all hosts
      darwinConfigurations = builtins.mapAttrs mkDarwinConfig hosts;

      # Formatter for nix files
      formatter.${hosts.hank-mstio.system} = nixpkgs.legacyPackages.${hosts.hank-mstio.system}.alejandra;
    };
}
