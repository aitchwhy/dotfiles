# macOS gesture and symbolic hotkey configuration
# Disables system gestures to allow Swish to intercept trackpad input
#
# Symbolic Hotkey IDs:
#   32 = Mission Control
#   33 = Application Windows (App Exposé)
#   34 = Show Desktop (F11)
#   35 = (unused)
#   36 = Show Desktop (another binding)
#   37 = Show Desktop (another binding)
#   160 = Launchpad
#   163 = Notification Center
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.modules.darwin.gestures;
in {
  options.modules.darwin.gestures = {
    enable = mkEnableOption "macOS gesture and hotkey customization";

    disableMissionControl = mkOption {
      type = types.bool;
      default = true;
      description = "Disable Mission Control keyboard shortcuts and gestures";
    };

    disableAppExpose = mkOption {
      type = types.bool;
      default = true;
      description = "Disable Application Windows (App Exposé) shortcut";
    };

    disableShowDesktop = mkOption {
      type = types.bool;
      default = true;
      description = "Disable Show Desktop shortcut";
    };

    disableLaunchpad = mkOption {
      type = types.bool;
      default = true;
      description = "Disable Launchpad gesture and shortcut";
    };

    disableNotificationCenter = mkOption {
      type = types.bool;
      default = true;
      description = "Disable Notification Center two-finger swipe from right edge";
    };
  };

  config = mkIf cfg.enable {
    # Disable symbolic hotkeys via com.apple.symbolichotkeys
    system.defaults.CustomUserPreferences."com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        # Mission Control
        "32" = {
          enabled = !cfg.disableMissionControl;
        };
        # Application Windows (App Exposé)
        "33" = {
          enabled = !cfg.disableAppExpose;
        };
        # Show Desktop variants
        "34" = {
          enabled = !cfg.disableShowDesktop;
        };
        "36" = {
          enabled = !cfg.disableShowDesktop;
        };
        "37" = {
          enabled = !cfg.disableShowDesktop;
        };
        # Launchpad
        "160" = {
          enabled = !cfg.disableLaunchpad;
        };
        # Notification Center
        "163" = {
          enabled = !cfg.disableNotificationCenter;
        };
      };
    };

    # Faster expose animation if it does get triggered
    system.defaults.dock.expose-animation-duration = 0.1;
  };
}
