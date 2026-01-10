# Custom packages overlay
# Packages not available in nixpkgs
{ pkgs }:
{
  mywhoop = pkgs.callPackage ./mywhoop.nix { };
}
