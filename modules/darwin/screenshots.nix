# macOS screenshot configuration
# Controls format, location, shadow, hotkeys, and other screenshot behavior
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
  cfg = config.modules.darwin.screenshots;

  # Helper to create a disabled symbolic hotkey entry
  disabledHotkey = {
    enabled = false;
  };
in
{
  options.modules.darwin.screenshots = {
    enable = mkEnableOption "macOS screenshot customization";

    location = mkOption {
      type = types.str;
      default = "~/Desktop/Screenshots";
      description = "Directory to save screenshots";
    };

    format = mkOption {
      type = types.enum [
        "png"
        "jpg"
        "pdf"
        "tiff"
        "gif"
        "bmp"
      ];
      default = "png";
      description = "Screenshot file format";
    };

    disableShadow = mkOption {
      type = types.bool;
      default = true;
      description = "Disable window shadow in screenshots";
    };

    includeDate = mkOption {
      type = types.bool;
      default = true;
      description = "Include date in screenshot filename";
    };

    showThumbnail = mkOption {
      type = types.bool;
      default = true;
      description = "Show floating thumbnail after capture";
    };

    disableSystemHotkeys = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Disable macOS built-in screenshot hotkeys (Cmd+Shift+3/4/5).
        Enable this when using third-party screenshot tools like CleanShot X
        that should capture these keybindings instead.
      '';
    };
  };

  config = mkIf cfg.enable {
    system.defaults.CustomUserPreferences."com.apple.screencapture" = {
      location = cfg.location;
      type = cfg.format;
      disable-shadow = cfg.disableShadow;
      include-date = cfg.includeDate;
      show-thumbnail = cfg.showThumbnail;
    };

    # Disable macOS screenshot hotkeys for third-party tools (e.g., CleanShot X)
    # Symbolic hotkey IDs:
    #   28 = Cmd+Shift+3 (capture screen to file)
    #   29 = Cmd+Ctrl+Shift+3 (capture screen to clipboard)
    #   30 = Cmd+Shift+4 (capture selection to file)
    #   31 = Cmd+Ctrl+Shift+4 (capture selection to clipboard)
    #  184 = Cmd+Shift+5 (screenshot/recording options)
    system.defaults.CustomUserPreferences."com.apple.symbolichotkeys" = mkIf cfg.disableSystemHotkeys {
      AppleSymbolicHotKeys = {
        "28" = disabledHotkey; # Cmd+Shift+3 (screen to file)
        "29" = disabledHotkey; # Cmd+Ctrl+Shift+3 (screen to clipboard)
        "30" = disabledHotkey; # Cmd+Shift+4 (selection to file)
        "31" = disabledHotkey; # Cmd+Ctrl+Shift+4 (selection to clipboard)
        "184" = disabledHotkey; # Cmd+Shift+5 (screenshot options)
      };
    };
  };
}
