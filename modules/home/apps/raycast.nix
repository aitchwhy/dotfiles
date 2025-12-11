# Raycast launcher configuration
# Key settings managed via plist defaults
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.modules.home.apps.raycast = {
    enable = mkEnableOption "Raycast launcher settings";
  };

  config = mkIf config.modules.home.apps.raycast.enable {
    targets.darwin.defaults."com.raycast.macos" = {
      # Global hotkey: Cmd+Space (49 = spacebar keycode)
      raycastGlobalHotkey = "Command-49";

      # Clipboard history
      "clipboardHistory_selectedContentTypeFilter" = "all";

      # Floating notes
      "floatingNotes_raycastNotesEditorTextSize" = "xxLarge";
      "floatingNotes_raycastNotesFormatBarVisible" = 1;

      # AI Chat hotkey dismissed
      aiChatHotkeyDismissed = 1;
    };

    # Store rayconfig export as reference (not actively imported by Raycast)
    # Extensions and other settings sync via Raycast account
    xdg.configFile."raycast/Raycast.rayconfig".source = ../../../config/raycast/Raycast.rayconfig;
  };
}
