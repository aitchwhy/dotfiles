# Swish trackpad gesture configuration
# Settings preserved from backup plist
{ config, lib, ... }:

with lib;

{
  options.modules.home.apps.swish = {
    enable = mkEnableOption "Swish trackpad gestures";
  };

  config = mkIf config.modules.home.apps.swish.enable {
    targets.darwin.defaults."co.highlyopinionated.swish" = {
      # Enabled gesture actions
      actions = ''["snapHalves","missionControlSpace","screensMove","tabDetach","appUnminimize","appCycle","snapVertical","appChain","appHide","snapMax","snapThirds","menubarAppSwitcher","windowFullscreen","appMinimize","tabClose","spacesMove","snapQuarters","snapCenter","windowClose","menubarScreens","windowQuit"]'';

      # Apps excluded from Swish gestures
      blacklist = ''["com.apple.CharacterPaletteIM","com.apple.PIPAgent","com.apple.controlcenter","com.apple.notificationcenterui","com.apple.Spotlight"]'';

      # Behavior settings
      hotkeys = 1;
      scrollingSensitivity = 2;
      showInMenubar = 1;
      snappingActivateWindow = 1;
      tapAndHold = 0;
    };
  };
}
