# NixOS configurations using withSystem for proper self/inputs passing
{
  self,
  inputs,
  withSystem,
  ...
}: {
  flake.nixosConfigurations.cloud = withSystem "x86_64-linux" (
    {...}:
      inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        # CRITICAL: Pass both inputs and self via specialArgs
        specialArgs = {inherit inputs self;};
        modules = [
          inputs.disko.nixosModules.disko
          inputs.sops-nix.nixosModules.sops
          ../hosts/cloud/configuration.nix
          ../modules/nixpkgs.nix
          ../modules/nixos

          # Home Manager for NixOS
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {inherit inputs self;};
              users.hank = import ../users/hank-linux.nix;
              backupFileExtension = "backup";
            };
          }
        ];
      }
  );
}
