# Safari browser configuration
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options.modules.darwin.safari = {
    enable = mkEnableOption "Safari customization";
  };

  config = mkIf config.modules.darwin.safari.enable {
    system.defaults.CustomUserPreferences."com.apple.Safari" = {
      # Developer settings
      IncludeInternalDebugMenu = true;
      IncludeDevelopMenu = true;
      WebKitDeveloperExtrasEnabledPreferenceKey = true;

      # Security
      AutoOpenSafeDownloads = false;

      # UI
      ShowFavoritesBar = false;
      ShowSidebarInTopSites = false;
      ShowFullURLInSmartSearchField = true;
    };
  };
}
