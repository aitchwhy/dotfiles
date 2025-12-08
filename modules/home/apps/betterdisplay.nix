# BetterDisplay configuration
# Display management: HiDPI scaling, DDC brightness control, resolution
# https://github.com/waydabber/BetterDisplay
#
# Best practices (Dec 2025):
# - BetterDisplay manages display-specific settings that macOS doesn't expose
# - No conflicts with nix-darwin: darwin modules handle system preferences,
#   BetterDisplay handles display hardware (DDC, EDID, scaling)
# - For DDC control: ensure displays support DDC/CI (most modern monitors do)
# - For HiDPI: use "flexible scaling" for non-retina 4K monitors
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.modules.home.apps.betterdisplay;
in
{
  options.modules.home.apps.betterdisplay = {
    enable = mkEnableOption "BetterDisplay configuration";

    startAtLogin = mkOption {
      type = types.bool;
      default = true;
      description = "Launch BetterDisplay at login";
    };

    showInMenuBar = mkOption {
      type = types.bool;
      default = true;
      description = "Show BetterDisplay icon in menu bar";
    };

    enableDDC = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enable DDC/CI control for external monitors.
        Allows hardware brightness/contrast control via monitor's OSD.
      '';
    };

    smoothTransitions = mkOption {
      type = types.bool;
      default = true;
      description = "Smooth brightness transitions instead of instant changes";
    };

    nativeOSD = mkOption {
      type = types.bool;
      default = true;
      description = "Show native macOS-style OSD for brightness changes";
    };

    protectLayout = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Protect display layout/arrangement from being reset.
        Useful when displays reconnect after sleep.
      '';
    };

    enableAccessibilityPermissionReminder = mkOption {
      type = types.bool;
      default = false;
      description = "Show reminder to grant Accessibility permission";
    };
  };

  config = mkIf cfg.enable {
    # BetterDisplay preferences via defaults
    # Bundle ID: pro.betterdisplay.BetterDisplay (since v4.0.3+)
    targets.darwin.defaults."pro.betterdisplay.BetterDisplay" = {
      # General
      startAtLogin = cfg.startAtLogin;
      showInMenuBar = cfg.showInMenuBar;
      accessibilityPermissionReminder = cfg.enableAccessibilityPermissionReminder;

      # DDC Control
      enableDDC = cfg.enableDDC;
      ddcAutoDetect = cfg.enableDDC;

      # Brightness behavior
      enableSmoothBrightnessTransitions = cfg.smoothTransitions;
      smoothBrightnessTransitionSpeed = 0.05; # Fast but smooth (0.01-0.1)

      # OSD (On-Screen Display)
      osdShowBasic = cfg.nativeOSD;
      osdShowCustom = true; # Show OSD for BetterDisplay-specific controls
      osdIntegrationNotification = true; # Enable third-party OSD integration (MediaMate)

      # Layout protection (prevents display rearrangement after sleep)
      enableLayoutProtection = cfg.protectLayout;

      # Resolution/scaling - let user configure per-display in app
      # These are display-specific and shouldn't be hardcoded

      # Performance
      reduceAnimations = false; # Keep animations for polish
      disableHardwareAcceleration = false;

      # PIP window defaults (Pro feature)
      pipShowResizePercent = false; # Less cluttered
      pipAutoWarp = true; # Warp cursor into PIP window

      # Stream defaults (Pro feature)
      screenStreamAutoWarp = true;
      screenStreamMouseHalo = false; # Clean look

      # Menu bar appearance
      sliderRevealAnimation = true; # Polish
    };
  };
}
