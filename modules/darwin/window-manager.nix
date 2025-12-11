# macOS Window Manager configuration
# Controls Stage Manager, desktop icons, and window behavior
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
  cfg = config.modules.darwin.windowManager;
in
{
  options.modules.darwin.windowManager = {
    enable = mkEnableOption "macOS Window Manager configuration";

    stageManager = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Stage Manager for window organization.";
    };

    clickToShowDesktop = mkOption {
      type = types.bool;
      default = false;
      description = "Click wallpaper to reveal desktop (hides windows)";
    };

    hideDesktopIcons = mkOption {
      type = types.bool;
      default = false;
      description = "Hide icons on desktop";
    };

    showMenuBarBackground = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Show solid menu bar background.
        macOS Tahoe 26+ uses floating "Liquid Glass" by default.
      '';
    };
  };

  config = mkIf cfg.enable {
    system.defaults.CustomUserPreferences."com.apple.WindowManager" = {
      GloballyEnabled = cfg.stageManager;
      EnableStandardClickToShowDesktop = if cfg.clickToShowDesktop then 1 else 0;
      StandardHideDesktopIcons = if cfg.hideDesktopIcons then 1 else 0;
      HideDesktop = if cfg.hideDesktopIcons then 1 else 0;
      StageManagerHideWidgets = 0;
      StandardHideWidgets = 0;
      # macOS Tahoe 26 - solid menu bar vs floating Liquid Glass
      ShowMenuBarBackground = cfg.showMenuBarBackground;
    };
  };
}
