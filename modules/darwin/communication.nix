# Apple Messages and FaceTime configuration
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg = config.modules.darwin.communication;
in
{
  options.modules.darwin.communication = {
    enable = mkEnableOption "Messages and FaceTime defaults";
  };

  config = mkIf cfg.enable {
    # Messages settings
    system.defaults.CustomUserPreferences."com.apple.MobileSMS" = {
      # Keep messages indefinitely
      "KeepMessageForDays" = 0;
    };

    # FaceTime settings
    system.defaults.CustomUserPreferences."com.apple.FaceTime" = {
      # No specific defaults needed - using system defaults
    };
  };
}
