{ config, pkgs, username, ... }:

{
  imports = [
    ./core.nix
    ./shell.nix
    ./git.nix
    ./starship.nix
  ];

  # This is handled by core.nix now
  home = {
    username = username;
    homeDirectory = "/Users/${username}";
    stateVersion = "24.05";
  };

  # Let home-manager manage itself
  programs.home-manager.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}
