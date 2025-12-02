# Option type helpers for creating module options
{ lib }:

with lib;

{
  # Boolean option with description
  mkBoolOpt = default: description: mkOption {
    type = types.bool;
    inherit default description;
  };

  # String option with description
  mkStrOpt = default: description: mkOption {
    type = types.str;
    inherit default description;
  };

  # Optional string option
  mkOptionalStrOpt = description: mkOption {
    type = types.nullOr types.str;
    default = null;
    inherit description;
  };

  # List option with element type
  mkListOpt = elemType: default: description: mkOption {
    type = types.listOf elemType;
    inherit default description;
  };

  # Attribute set option
  mkAttrsOpt = default: description: mkOption {
    type = types.attrs;
    inherit default description;
  };

  # Enum option
  mkEnumOpt = values: default: description: mkOption {
    type = types.enum values;
    inherit default description;
  };

  # Integer option with bounds
  mkIntOpt = min: max: default: description: mkOption {
    type = types.ints.between min max;
    inherit default description;
  };

  # Package option
  mkPackageOpt = default: description: mkOption {
    type = types.package;
    inherit default description;
  };

  # Path option
  mkPathOpt = default: description: mkOption {
    type = types.path;
    inherit default description;
  };

  # Submodule option
  mkSubmoduleOpt = options: default: description: mkOption {
    type = types.submodule { inherit options; };
    inherit default description;
  };

  # Enable option (common pattern)
  mkEnableOpt = description: mkOption {
    type = types.bool;
    default = false;
    inherit description;
  };
}
