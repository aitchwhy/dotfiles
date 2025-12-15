# Slack messaging client configuration
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
  cfg = config.modules.home.apps.slack;
in
{
  options.modules.home.apps.slack = {
    enable = mkEnableOption "Slack client settings";
  };

  config = mkIf cfg.enable {
    # Slack uses com.tinyspeck.slackmacgap for some settings
    # Most configuration is synced via Slack account
    targets.darwin.defaults."com.tinyspeck.slackmacgap" = {
      # Slack settings are primarily account-synced
    };
  };
}
