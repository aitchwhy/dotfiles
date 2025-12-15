# Apple Mail configuration
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
  cfg = config.modules.darwin.mail;
in
{
  options.modules.darwin.mail = {
    enable = mkEnableOption "Apple Mail defaults";

    enableContactPhotos = mkOption {
      type = types.bool;
      default = true;
      description = "Show contact photos in message list";
    };

    columnLayout = mkOption {
      type = types.bool;
      default = false;
      description = "Use column layout for message list (classic 3-column view)";
    };
  };

  config = mkIf cfg.enable {
    system.defaults.CustomUserPreferences."com.apple.mail" = {
      # Contact photos in message list
      EnableContactPhotos = cfg.enableContactPhotos;

      # Message list layout (0 = rows, 1 = columns)
      ColumnLayoutMessageList = if cfg.columnLayout then 1 else 0;
    };
  };
}
