# Zellij Configuration Validators
#
# Type-safe validation for Zellij KDL configuration files.
# Validates patterns at Nix evaluation time.
#
# Key validations:
# - Config file exists
# - No Alt+Arrow bindings (conflict with macOS word navigation)
# - Required keybindings present
{
  lib,
  src,
  validators,
  assertions,
}:
let
  inherit (validators) fileExists fileContains fileContainsAny;
  inherit (assertions) mkTest mkAssertion;

  # Base paths
  zellijDir = "config/zellij";
  configFile = "${zellijDir}/config.kdl";

  # ===========================================================================
  # ANTI-PATTERNS (must NOT exist)
  # ===========================================================================

  # Alt+Arrow conflicts with macOS word navigation
  altArrowPatterns = [
    ''bind "Alt left"''
    ''bind "Alt right"''
    ''bind "Alt up"''
    ''bind "Alt down"''
  ];

  # ===========================================================================
  # VALIDATORS
  # ===========================================================================

  configExists = fileExists configFile;

  hasAltArrowConflict = fileContainsAny configFile altArrowPatterns;

in
{
  # ===========================================================================
  # TESTS (for lib.debug.runTests)
  # ===========================================================================

  tests = {
    "zellij-config-exists" = {
      expr = configExists;
      expected = true;
    };

    "zellij-no-alt-arrow-bindings" = {
      expr = !configExists || !hasAltArrowConflict;
      expected = true;
    };
  };

  # ===========================================================================
  # ASSERTIONS (for module system)
  # ===========================================================================

  assertions = [
    (mkAssertion "zellij-config-exists" configExists "Zellij config file not found: ${configFile}")

    (mkAssertion "zellij-no-alt-arrow" (
      !configExists || !hasAltArrowConflict
    ) "Zellij config must not use Alt+Arrow bindings (conflicts with macOS word navigation)")
  ];

  # ===========================================================================
  # METADATA
  # ===========================================================================

  meta = {
    name = "zellij";
    description = "Zellij configuration validation";
    configFile = configFile;
  };
}
