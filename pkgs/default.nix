# Custom packages overlay
# Packages not available in nixpkgs
{ pkgs }:
{
  mywhoop = pkgs.callPackage ./mywhoop.nix { };
  ralph-claude-code = pkgs.callPackage ./ralph-claude-code.nix { };
}
