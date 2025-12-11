# macOS keyboard shortcut configuration
# Disables Spotlight shortcuts to allow Raycast to use Cmd+Space
#
# Trackpad gestures are managed by Swish app (installed via homebrew casks)
#
# Symbolic Hotkey IDs:
#   64 = Spotlight Search (Cmd+Space)
#   65 = Spotlight Finder Search (Cmd+Opt+Space)
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
  cfg = config.modules.darwin.keyboard;
in
{
  options.modules.darwin.keyboard = {
    enable = mkEnableOption "macOS keyboard shortcut customization";

    disableSpotlight = mkOption {
      type = types.bool;
      default = true;
      description = "Disable Spotlight shortcuts (Cmd+Space) to allow Raycast";
    };
  };

  config = mkIf cfg.enable {
    # Disable symbolic hotkeys via com.apple.symbolichotkeys
    system.defaults.CustomUserPreferences."com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        # Spotlight Search (Cmd+Space) - let Raycast handle it
        "64" = {
          enabled = !cfg.disableSpotlight;
        };
        # Spotlight Finder Search (Cmd+Opt+Space)
        "65" = {
          enabled = !cfg.disableSpotlight;
        };
      };
    };
  };
}
