# Testing Library - Single Source of Truth for Flake Checks
#
# SOTA Nix testing patterns (January 2026):
# - Pure Nix assertions (no bash scripts)
# - lib.debug.runTests for structured test output
# - Type-safe validators with meaningful error messages
# - DRY: Reusable assertion builders
#
# Usage in flake checks:
#   let
#     testing = import ./lib/testing { inherit lib; src = ./.; };
#   in {
#     checks.${system} = testing.allChecks;
#   }
{ lib, src }:
let
  # Import sub-modules
  assertions = import ./assertions.nix { inherit lib; };
  validators = import ./validators.nix { inherit lib src; };
  neovim = import ./neovim.nix {
    inherit
      lib
      src
      validators
      assertions
      ;
  };
  zellij = import ./zellij.nix {
    inherit
      lib
      src
      validators
      assertions
      ;
  };
  quality = import ./quality.nix {
    inherit
      lib
      src
      validators
      assertions
      ;
  };

in
{
  # Re-export modules for direct access
  inherit
    assertions
    validators
    neovim
    zellij
    quality
    ;

  # All tests as a single attrset for lib.debug.runTests
  allTests = neovim.tests // zellij.tests // quality.tests;

  # Run all tests - returns [] on success, list of failures otherwise
  runAllTests = lib.debug.runTests (neovim.tests // zellij.tests // quality.tests);

  # Module-system assertions (for nix-darwin/home-manager integration)
  allAssertions = neovim.assertions ++ zellij.assertions ++ quality.assertions;
}
