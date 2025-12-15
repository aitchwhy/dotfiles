# Flake packages module
# Exposes custom packages built from this repository
#
# Signet Package Architecture (Dec 2025):
#   Uses bun2nix.hook for automated cache setup and dependency installation.
#   Custom bundling preserves native modules (@ast-grep/napi, oxc-parser)
#   that cannot be compiled into standalone binaries.
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
        # Hermetically packaged with pre-bundled JavaScript
        signet = pkgs.stdenv.mkDerivation {
          pname = "signet";
          version = "2.0.0";

          src = ../config/signet;

          nativeBuildInputs = [
            pkgs.bun
            pkgs.makeWrapper
            bun2nix.hook # Handles cache setup and bun install automatically
          ];

          # bun2nix.hook requires bunDeps - the pre-fetched dependency cache
          bunDeps = bun2nix.fetchBunDeps {
            bunNix = ../config/signet/bun.nix;
          };

          # Disable default bun phases - we do custom TypeScript bundling
          dontUseBunBuild = true;
          dontUseBunCheck = true;
          dontUseBunInstall = true;
          dontPatchELF = true;

          buildPhase = ''
            runHook preBuild

            # Bundle TypeScript to JavaScript
            # External: native modules that must be loaded from node_modules at runtime
            mkdir -p dist
            bun build src/cli.ts \
              --target bun \
              --outfile dist/cli.js \
              --minify \
              --external '@ast-grep/napi' \
              --external 'oxc-parser'

            bun build src/mcp-server.ts \
              --target bun \
              --outfile dist/mcp-server.js \
              --minify \
              --external '@ast-grep/napi' \
              --external 'oxc-parser'

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            # Create output directories
            mkdir -p $out/bin $out/lib/signet

            # Copy bundled JavaScript
            cp -r dist $out/lib/signet/

            # Copy node_modules for native module access at runtime
            cp -r node_modules $out/lib/signet/

            # Create wrapper script for CLI
            makeWrapper ${pkgs.bun}/bin/bun $out/bin/signet \
              --add-flags "run $out/lib/signet/dist/cli.js" \
              --set NODE_PATH "$out/lib/signet/node_modules" \
              --chdir "$out/lib/signet"

            # Create wrapper script for MCP server
            makeWrapper ${pkgs.bun}/bin/bun $out/bin/signet-mcp \
              --add-flags "run $out/lib/signet/dist/mcp-server.js" \
              --set NODE_PATH "$out/lib/signet/node_modules" \
              --chdir "$out/lib/signet"

            runHook postInstall
          '';

          meta = {
            description = "Code Quality & Generation Platform - hexagonal architecture enforcer";
            mainProgram = "signet";
          };
        };
      };
    };
}
