# Validation functions for configuration values
{ lib }:

with lib;

rec {
  # Validate email address format
  validateEmail = email:
    let
      emailRegex = "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}";
    in
    builtins.match emailRegex email != null;

  # Validate hostname format
  validateHostname = hostname:
    let
      hostnameRegex = "^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$";
    in
    builtins.match hostnameRegex hostname != null;

  # Validate username format
  validateUsername = username:
    let
      usernameRegex = "^[a-z_][a-z0-9_-]{0,31}$";
    in
    builtins.match usernameRegex username != null;

  # Validate IP address
  validateIP = ip:
    let
      ipRegex = "^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])\\.){3}(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])$";
    in
    builtins.match ipRegex ip != null;

  # Validate port number
  validatePort = port:
    port >= 1 && port <= 65535;

  # Validate path exists
  validatePath = path:
    builtins.pathExists path;

  # Validate package name
  validatePackageName = name:
    let
      pkgRegex = "^[a-zA-Z0-9][a-zA-Z0-9._-]*$";
    in
    builtins.match pkgRegex name != null;

  # Create assertion helper
  mkAssertion = condition: message: {
    assertion = condition;
    inherit message;
  };

  # Validate module config with assertions
  validateConfig = config: assertions:
    let
      failures = filter (a: !a.assertion) assertions;
    in
    if failures == [ ] then config
    else throw "Configuration validation failed:\n" +
      concatMapStringsSep "\n" (a: "  - ${a.message}") failures;

  # Common assertions
  assertNonEmpty = value: name:
    mkAssertion (value != "" && value != null)
      "${name} must not be empty";

  assertInRange = value: min: max: name:
    mkAssertion (value >= min && value <= max)
      "${name} must be between ${toString min} and ${toString max}";

  assertOneOf = value: allowed: name:
    mkAssertion (elem value allowed)
      "${name} must be one of: ${concatStringsSep ", " allowed}";

  assertValidPath = path: name:
    mkAssertion (validatePath path)
      "${name} path does not exist: ${path}";
}
