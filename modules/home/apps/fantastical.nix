# Fantastical calendar app configuration
# https://flexibits.com/fantastical
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.modules.home.apps.fantastical;
in
{
  options.modules.home.apps.fantastical = {
    enable = mkEnableOption "Fantastical calendar settings";

    daysPerWeek = mkOption {
      type = types.int;
      default = 7;
      description = "Number of days to show in week view";
    };

    weekStartsOn = mkOption {
      type = types.enum [
        0
        1
        2
      ]; # 0=Sunday, 1=Monday, 2=Saturday
      default = 1;
      description = "Day the week starts on (0=Sunday, 1=Monday, 2=Saturday)";
    };

    weeksPerMonth = mkOption {
      type = types.int;
      default = 6;
      description = "Number of weeks to show in month view";
    };
  };

  config = mkIf cfg.enable {
    targets.darwin.defaults."com.flexibits.fantastical2.mac" = {
      # View settings
      DaysPerWeek = cfg.daysPerWeek;
      WeekViewStartsWith = cfg.weekStartsOn;
      WeeksPerMonth = cfg.weeksPerMonth;

      # Auto-updates
      SUAutomaticallyUpdate = true;
      SUEnableAutomaticChecks = true;
    };
  };
}
