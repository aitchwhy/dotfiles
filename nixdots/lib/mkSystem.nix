# System builder abstractions
{ lib }:

let
  # Common module imports for all systems
  commonModules = [
    # Core modules are imported in flake.nix directly
  ];

  # Platform-specific module imports
  darwinModules = [
    # Platform modules are imported in flake.nix directly
  ];

  linuxModules = [
    # Linux modules would go here
  ];

in
rec {
  # Create a Darwin system configuration
  mkDarwinSystem =
    { system ? "aarch64-darwin"
    , hostname
    , username
    , extraModules ? [ ]
    , homeConfig ? null
    , specialArgs ? { }
    }:
    let
      darwinLib = inputs: inputs.nix-darwin.lib;
    in
    inputs: (darwinLib inputs).darwinSystem {
      inherit system;
      specialArgs = specialArgs // { inherit inputs; };

      modules = commonModules
        ++ darwinModules
        ++ extraModules
        ++ [
        # Host-specific configuration handled by flake.nix

        # User configuration
        ({ pkgs, ... }: {
          users.users.${username} = {
            description = username;
            home = "/Users/${username}";
            shell = pkgs.zsh;
          };

          networking.hostName = hostname;
          system.primaryUser = username;

          programs.zsh.enable = true;
          environment.shells = with pkgs; [ bashInteractive zsh ];
        })

        # Home-manager integration if provided
      ] ++ lib.optional (homeConfig != null) [
        inputs.home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = specialArgs // { inherit inputs; };
            users.${username} = homeConfig;
          };
        }
      ];
    };

  # Create a Linux system configuration
  mkLinuxSystem =
    { system ? "x86_64-linux"
    , hostname
    , username
    , extraModules ? [ ]
    , homeConfig ? null
    , specialArgs ? { }
    }: inputs: inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = specialArgs // { inherit inputs; };

      modules = commonModules
        ++ linuxModules
        ++ extraModules
        ++ [
        # Host-specific configuration handled by flake.nix

        # User configuration
        ({ pkgs, ... }: {
          users.users.${username} = {
            isNormalUser = true;
            description = username;
            home = "/home/${username}";
            shell = pkgs.zsh;
            extraGroups = [ "wheel" "networkmanager" "docker" ];
          };

          networking.hostName = hostname;
          programs.zsh.enable = true;
        })

        # Home-manager integration if provided
      ] ++ lib.optional (homeConfig != null) [
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = specialArgs // { inherit inputs; };
            users.${username} = homeConfig;
          };
        }
      ];
    };
}
