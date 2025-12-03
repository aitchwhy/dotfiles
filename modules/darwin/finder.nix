# macOS Finder configuration
{ config, lib, ... }:

with lib;

{
  options.modules.darwin.finder = {
    enable = mkEnableOption "macOS Finder customization";

    showHiddenFiles = mkOption {
      type = types.bool;
      default = true;
      description = "Show hidden files in Finder";
    };

    defaultView = mkOption {
      type = types.enum [ "icon" "list" "column" "gallery" ];
      default = "column";
      description = "Default Finder view style";
    };
  };

  config = mkIf config.modules.darwin.finder.enable {
    system.defaults.finder = {
      # Visibility
      AppleShowAllFiles = config.modules.darwin.finder.showHiddenFiles;
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      _FXShowPosixPathInTitle = true;

      # Behavior
      FXEnableExtensionChangeWarning = false;
      QuitMenuItem = true;
      FXDefaultSearchScope = "SCcf"; # Search current folder

      # View settings
      FXPreferredViewStyle = {
        icon = "icnv";
        list = "Nlsv";
        column = "clmv";
        gallery = "glyv";
      }.${config.modules.darwin.finder.defaultView};

      # New window settings
      NewWindowTarget = "Other";
      NewWindowTargetPath = "file:///Users/hank/";
    };

    # Additional Finder settings via CustomUserPreferences
    system.defaults.CustomUserPreferences."com.apple.finder" = {
      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = true;
      ShowMountedServersOnDesktop = true;
      ShowRemovableMediaOnDesktop = true;
      _FXSortFoldersFirst = true;
    };

    # Prevent .DS_Store files on network and USB volumes
    system.defaults.CustomUserPreferences."com.apple.desktopservices" = {
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };
  };
}
