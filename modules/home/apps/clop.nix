# Clop image optimizer configuration
# https://github.com/FuzzyIdeas/Clop
# Bundle ID: com.lowtechguys.Clop-setapp
#
# CLIPBOARD OPTIMIZATION DISABLED (Feb 2026)
# Reason: Causes duplicate clipboard entries in Paste after CleanShot X screenshots
# - CleanShot X captures PNG → Paste captures it
# - Clop optimizes PNG to JPEG → Paste captures duplicate
# Result: User sees two entries in clipboard history
#
# DIRECTORY OPTIMIZATION ENABLED
# Clop still monitors and optimizes files in:
# - ~/Desktop
# - ~/Downloads
# Conversions: WebP/AVIF/HEIC/BMP → JPEG, Videos → MP4
#
# MANUAL CONFIGURATION REQUIRED:
# Clop via Setapp may have limited defaults exposure
# After rebuild, configure via Clop app:
# 1. Open Clop app
# 2. Preferences → Clipboard tab
# 3. Uncheck "Automatically optimize clipboard images"
# 4. Keep "Watch folders" enabled for Desktop/Downloads
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.home.apps.clop;
in
{
  options.modules.home.apps.clop = {
    enable = mkEnableOption "Clop image optimizer settings";
  };

  config = mkIf cfg.enable {
    # Clop preferences are primarily managed via Setapp app UI
    # Most settings are not exposed as macOS defaults
    # This module exists for declarative tracking and documentation
    #
    # To disable clipboard optimization manually:
    # Clop app → Preferences → Clipboard → Uncheck "Optimize clipboard images"
    #
    # To configure watched directories:
    # Clop app → Preferences → Folders → Enable/disable Desktop, Downloads, etc.
  };
}
