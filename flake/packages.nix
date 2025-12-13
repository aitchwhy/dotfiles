# Flake packages module
# Exposes custom packages built from this repository
#
# Signet Package Architecture (Dec 2025):
#   1. signetBunDeps - Cached by bun.lock hash (content-addressed bun cache)
#   2. signet - Installs deps from cache, bundles TypeScript, creates wrappers
#
# Why bundling instead of standalone binary:
#   Native modules (@ast-grep/napi, oxc-parser) cannot be compiled
#   into standalone binaries. We bundle TypeScript to JavaScript
#   for faster startup while keeping native modules in node_modules.
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

      # Fetch dependencies - content-addressed by bun.lock hash
      # This is the expensive derivation that gets cached
      signetBunDeps = bun2nix.fetchBunDeps {
        bunNix = ../config/signet/bun.nix;
      };
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
          ];

          # No network access needed - deps come from signetBunDeps cache
          dontPatchELF = true;

          # Following bun2nix hook.sh pattern:
          # 1. Copy bun-cache to BUN_INSTALL_CACHE_DIR
          # 2. Run bun install (which creates node_modules from cache)
          # 3. Bundle TypeScript
          buildPhase = ''
            runHook preBuild

            # Set up bun's install cache from pre-fetched deps
            export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
            cp -r ${signetBunDeps}/share/bun-cache/. "$BUN_INSTALL_CACHE_DIR"

            # Need writable HOME for bun
            export HOME=$(mktemp -d)

            # Install dependencies from cache (offline, no network)
            # Use bun2nix's recommended flags for Darwin: --linker=isolated --backend=symlink
            bun install --linker=isolated --backend=symlink --ignore-scripts

            # Make node_modules writable for lifecycle scripts
            chmod -R u+rwx ./node_modules

            # Run lifecycle scripts (native module builds)
            bun install --linker=isolated --backend=symlink

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

        # Also expose the bun deps derivation for debugging
        inherit signetBunDeps;
      };
    };
}
