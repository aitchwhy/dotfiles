# Apple Calendar configuration
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
  cfg = config.modules.darwin.calendar;
in
{
  options.modules.darwin.calendar = {
    enable = mkEnableOption "Apple Calendar defaults";

    showWeekNumbers = mkOption {
      type = types.bool;
      default = true;
      description = "Show week numbers in calendar";
    };

    timezoneSupport = mkOption {
      type = types.bool;
      default = true;
      description = "Enable timezone support";
    };

    defaultEventDuration = mkOption {
      type = types.int;
      default = 30;
      description = "Default duration in minutes for new events";
    };

    showHeatMap = mkOption {
      type = types.bool;
      default = true;
      description = "Show heat map in Year View";
    };
  };

  config = mkIf cfg.enable {
    system.defaults.CustomUserPreferences."com.apple.iCal" = {
      # Week numbers
      "Show Week Numbers" = cfg.showWeekNumbers;

      # Timezone support
      "TimeZone support enabled" = cfg.timezoneSupport;

      # Default event duration
      "Default duration in minutes for new event" = cfg.defaultEventDuration;

      # Year view heat map
      "Show heat map in Year View" = cfg.showHeatMap;

      # Work hours (7am - 4pm)
      "first minute of work hours" = 420; # 7:00 AM
      "last minute of work hours" = 960; # 4:00 PM
    };
  };
}
