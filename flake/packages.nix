# Flake packages module
# Exposes custom packages built from this repository
{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      system,
      ...
    }:
    let
      # bun2nix v2 API: functions are on the package, not lib
      bun2nix = inputs.bun2nix.packages.${system}.default;
    in
    {
      packages = {
        # Signet - Code Quality & Generation Platform
        # Hermetically packaged with bun2nix v2
        # Uses writeBunApplication for CLI tools that run via `bun run`
        signet = bun2nix.writeBunApplication {
          pname = "signet";
          version = "2.0.0";

          src = ../config/signet;

          # Skip bun build - this is a CLI that runs via `bun run`, not compiled
          # The hook only uses bunBuildPhase if both dontUseBunBuild and buildPhase are unset
          dontUseBunBuild = true;

          # Entry point script (runs: bun run src/cli.ts "$@")
          startScript = ''
            bun run src/cli.ts "$@"
          '';

          # Fetch dependencies from generated bun.nix
          bunDeps = bun2nix.fetchBunDeps {
            bunNix = ../config/signet/bun.nix;
          };
        };
      };
    };
}
