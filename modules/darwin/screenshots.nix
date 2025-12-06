# macOS screenshot configuration
# Controls format, location, shadow, and other screenshot behavior
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.modules.darwin.screenshots;
in {
  options.modules.darwin.screenshots = {
    enable = mkEnableOption "macOS screenshot customization";

    location = mkOption {
      type = types.str;
      default = "~/Desktop/Screenshots";
      description = "Directory to save screenshots";
    };

    format = mkOption {
      type = types.enum ["png" "jpg" "pdf" "tiff" "gif" "bmp"];
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
  };

  config = mkIf cfg.enable {
    system.defaults.CustomUserPreferences."com.apple.screencapture" = {
      location = cfg.location;
      type = cfg.format;
      disable-shadow = cfg.disableShadow;
      include-date = cfg.includeDate;
      show-thumbnail = cfg.showThumbnail;
    };
  };
}
