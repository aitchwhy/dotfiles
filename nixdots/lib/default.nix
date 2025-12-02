# Central library for Nix configuration helpers
{ lib }:

rec {
  # Import all library modules
  mkSystem = import ./mkSystem.nix { inherit lib; };
  options = import ./options.nix { inherit lib; };
  utils = import ./utils.nix { inherit lib; };
  validators = import ./validators.nix { inherit lib; };

  # Re-export for convenience
  inherit (mkSystem) mkDarwinSystem mkLinuxSystem;
  inherit (options) mkBoolOpt mkStrOpt mkListOpt mkAttrsOpt;
  inherit (utils) mkIfDarwin mkIfLinux mkIfHome filterEnabled;
  inherit (validators) validateEmail validateHostname validateUsername;
}
