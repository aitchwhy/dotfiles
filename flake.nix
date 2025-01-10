# flake.nix
{
  description = "hank's nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Darwin system configuration
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { 
    nixpkgs, 
    darwin, 
    home-manager,
    ...
  }: {
    darwinConfigurations."hank-mbp-m3" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ./darwin/configuration.nix
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.hank = import ./home/home.nix;
          };
          users.users.hank.home = "/Users/hank";
          # nix.settings.trusted-users = [ hank ];
        }
      ];
    };

    darwinConfigurations."hank-mstio" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ./darwin/configuration.nix
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.hank = import ./home/home.nix;
          };
          users.users.hank.home = "/Users/hank";
          # nix.settings.trusted-users = [ hank ];
        }
      ];
    };
  };
}
