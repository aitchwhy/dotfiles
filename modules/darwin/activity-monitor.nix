# Activity Monitor configuration
{
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.modules.darwin.activityMonitor;

  # IconType values from macos-defaults.com
  iconTypeMap = {
    app = 0; # Application icon only
    network = 2; # Network usage
    disk = 3; # Disk activity
    cpu = 5; # CPU usage meter
    cpuHistory = 6; # CPU history graph
  };
in {
  options.modules.darwin.activityMonitor = {
    enable = mkEnableOption "Activity Monitor customization";

    iconType = mkOption {
      type = types.enum [
        "app"
        "network"
        "disk"
        "cpu"
        "cpuHistory"
      ];
      default = "cpu";
      description = ''
        Dock icon display type for Activity Monitor:
        - app: Application icon only
        - network: Network usage indicator
        - disk: Disk activity indicator
        - cpu: CPU usage meter (default)
        - cpuHistory: CPU history graph
      '';
    };
  };

  config = mkIf cfg.enable {
    system.defaults.CustomUserPreferences."com.apple.ActivityMonitor" = {
      OpenMainWindow = true;
      IconType = iconTypeMap.${cfg.iconType};
      ShowCategory = 0;
      SortColumn = "CPUUsage";
      SortDirection = 0;
    };
  };
}
