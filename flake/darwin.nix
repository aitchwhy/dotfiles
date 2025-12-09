# Darwin configurations using withSystem for proper self/inputs passing
{
  self,
  inputs,
  withSystem,
  ...
}:
{
  flake.darwinConfigurations.hank-mbp-m4 = withSystem "aarch64-darwin" (
    { pkgs, ... }:
    inputs.nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      # CRITICAL: Pass both inputs and self via specialArgs
      specialArgs = { inherit inputs self; };
      modules = [
        inputs.sops-nix.darwinModules.sops
        ../modules/nixpkgs.nix
        ../modules/darwin
        ../modules/homebrew.nix
        ../hosts/hank-mbp-m4.nix

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
        inputs.home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs self; };
            users.hank = import ../users/hank.nix;
            backupFileExtension = "backup";
          };
        }

        # Homebrew
        inputs.nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            user = "hank";
            autoMigrate = true;
          };
        }
      ];
    }
  );
}
