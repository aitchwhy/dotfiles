# Paste clipboard manager
# https://pasteapp.io/
# Bundle ID: com.wiheads.paste
#
# PRIMARY CLIPBOARD MANAGER (Feb 2026)
# - Raycast clipboard history: DISABLED (known reliability bug)
# - Clop clipboard monitoring: DISABLED (causes duplicate entries)
# - Wispr Flow transcriptions: Won't appear in history (save/restore pattern)
#
# Mac App Store app (ID: 967805235)
# Login item: Managed via macOS System Settings > General > Login Items
# Database: ~/Library/Containers/com.wiheads.paste/Data/Library/Application Support/Paste/
# Current size: ~1.2GB (as of Feb 2026)
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.home.apps.paste;
in
{
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
