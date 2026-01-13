# Custom packages overlay
# Packages not available in nixpkgs
{ pkgs }:
{
  agent-browser = pkgs.callPackage ./agent-browser.nix { };
  drizzle-kit = pkgs.callPackage ./drizzle-kit.nix { };
  mywhoop = pkgs.callPackage ./mywhoop.nix { };
  ralph-claude-code = pkgs.callPackage ./ralph-claude-code.nix { };
}
