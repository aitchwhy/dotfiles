# Spotify music client configuration
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
  cfg = config.modules.home.apps.spotify;
in
{
  options.modules.home.apps.spotify = {
    enable = mkEnableOption "Spotify client settings";
  };

  config = mkIf cfg.enable {
    targets.darwin.defaults."com.spotify.client" = {
      # Auto-start on login is handled by Spotify itself
      # Most settings are synced via Spotify account
    };
  };
}
