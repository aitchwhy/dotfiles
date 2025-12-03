# Activity Monitor configuration
{ config, lib, ... }:

with lib;

{
  options.modules.darwin.activityMonitor = {
    enable = mkEnableOption "Activity Monitor customization";
  };

  config = mkIf config.modules.darwin.activityMonitor.enable {
    system.defaults.CustomUserPreferences."com.apple.ActivityMonitor" = {
      OpenMainWindow = true;
      IconType = 5;
      ShowCategory = 0;
      SortColumn = "CPUUsage";
      SortDirection = 0;
    };
  };
}
