# macOS keyboard shortcut configuration
# Disables system shortcuts to allow third-party apps to use them
#
# Trackpad gestures are managed by Swish app (installed via homebrew casks)
#
# Symbolic Hotkey IDs:
#   60 = Show Emoji & Symbols (Ctrl+Cmd+Space)
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

    disableEmojiPicker = mkOption {
      type = types.bool;
      default = true;
      description = "Disable Emoji & Symbols shortcut (Ctrl+Cmd+Space) to allow Wispr Flow";
    };
  };

  config = mkIf cfg.enable {
    # Disable symbolic hotkeys via com.apple.symbolichotkeys
    system.defaults.CustomUserPreferences."com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        # Show Emoji & Symbols (Ctrl+Cmd+Space) - let Wispr Flow use it
        "60" = {
          enabled = !cfg.disableEmojiPicker;
        };
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
