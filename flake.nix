{
  description = "Hank's Nix Configuration";

  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    warn-dirty = false;
    accept-flake-config = true;
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nix-homebrew,
      ...
    }@inputs:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      darwinConfigurations.hank-mbp-m4 = nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit inputs self; };
        modules = [
          ./modules/nixpkgs.nix
          ./modules/darwin
          ./modules/homebrew.nix
          ./hosts/hank-mbp-m4.nix

          # User configuration
          {
            system.primaryUser = "hank";
            users.users.hank = {
              uid = 501;
              description = "Hank Lee";
              home = "/Users/hank";
              shell = pkgs.zsh;
            };
            programs.zsh.enable = true;
            environment.shells = [
              pkgs.bashInteractive
              pkgs.zsh
            ];
          }

          # Home Manager
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs self; };
              users.hank = import ./users/hank.nix;
              backupFileExtension = "backup";
            };
          }

          # Homebrew
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              user = "hank";
              autoMigrate = true;
            };
          }
        ];
      };

      # Development shell
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nixd
          nixfmt-rfc-style
          deadnix
          statix
          just
          git
          fd
        ];
        shellHook = ''
          echo "Nix Darwin Dev Shell"
          echo "  rebuild  - darwin-rebuild switch --flake .#hank-mbp-m4"
          echo "  update   - nix flake update"
        '';
      };

      formatter.${system} = pkgs.nixfmt-rfc-style;
    };
}
