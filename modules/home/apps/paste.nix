# Paste clipboard manager
# https://pasteapp.io/
# Bundle ID: com.wiheads.paste
#
# Mac App Store app (ID: 967805235)
# Login item: Managed via macOS System Settings > General > Login Items
# (Mac App Store apps don't expose startAtLogin via plist defaults)
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.home.apps.paste;
in {
  options.modules.home.apps.paste = {
    enable = mkEnableOption "Paste clipboard manager tracking";
  };

  config = mkIf cfg.enable {
    # Paste preferences that CAN be configured via defaults:
    # - kPSTPreferencesActivationShortcut (complex JSON structure)
    # - kPSTPreferencesBlackAppsBundles (apps to exclude from capture)
    #
    # Most settings are managed via Paste's UI and iCloud sync.
    # This module exists for declarative tracking and documentation.
    #
    # To add Paste as a login item manually:
    # System Settings > General > Login Items > Add "Paste"
  };
}
