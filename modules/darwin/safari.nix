# Safari browser configuration
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
  cfg = config.modules.darwin.safari;
in
{
  options.modules.darwin.safari = {
    enable = mkEnableOption "Safari browser defaults";

    autoOpenSafeDownloads = mkOption {
      type = types.bool;
      default = false;
      description = "Automatically open safe downloads";
    };

    includeDevelopMenu = mkOption {
      type = types.bool;
      default = true;
      description = "Show Develop menu in menu bar";
    };

    showFullUrl = mkOption {
      type = types.bool;
      default = true;
      description = "Show full URL in Smart Search field";
    };
  };

  config = mkIf cfg.enable {
    system.defaults.CustomUserPreferences."com.apple.Safari" = {
      # Downloads
      AutoOpenSafeDownloads = cfg.autoOpenSafeDownloads;

      # Developer
      IncludeDevelopMenu = cfg.includeDevelopMenu;
      IncludeInternalDebugMenu = cfg.includeDevelopMenu;
      WebKitDeveloperExtrasEnabledPreferenceKey = cfg.includeDevelopMenu;
      "WebKitPreferences.developerExtrasEnabled" = cfg.includeDevelopMenu;

      # URL bar
      ShowFullURLInSmartSearchField = cfg.showFullUrl;

      # Security
      UseHTTPSOnly = true;
      PrivateBrowsingRequiresAuthentication = true;

      # Extensions
      ExtensionsEnabled = true;

      # Reading list
      ReadingListSaveArticlesOfflineAutomatically = true;

      # Sidebar
      ShowSidebarInNewWindows = true;

      # Privacy
      "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" =
        cfg.includeDevelopMenu;
    };
  };
}
