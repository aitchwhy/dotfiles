# Wispr Flow voice dictation - manual installation via activation script
# No Homebrew cask available, downloads directly from wisprflow.ai
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options.modules.darwin.apps.wisprFlow = {
    enable = mkEnableOption "Wispr Flow voice dictation";
  };

  config = mkIf config.modules.darwin.apps.wisprFlow.enable {
    # Use extraActivation which runs as root
    system.activationScripts.extraActivation.text = ''
      # Download and install Wispr Flow if not present
      WISPR_APP="/Applications/Wispr Flow.app"

      if [ ! -d "$WISPR_APP" ]; then
        echo "Installing Wispr Flow..."
        TEMP_DIR=$(mktemp -d)

        # Detect architecture and download appropriate version
        if [ "$(uname -m)" = "arm64" ]; then
          DOWNLOAD_URL="https://dl.wisprflow.ai/mac-apple/latest"
        else
          DOWNLOAD_URL="https://dl.wisprflow.ai/mac-intel/latest"
        fi

        # Download DMG
        /usr/bin/curl -L -o "$TEMP_DIR/WisprFlow.dmg" "$DOWNLOAD_URL"

        # Mount DMG
        hdiutil attach "$TEMP_DIR/WisprFlow.dmg" -nobrowse -quiet

        # Copy app to Applications
        if [ -d "/Volumes/Wispr Flow/Wispr Flow.app" ]; then
          cp -R "/Volumes/Wispr Flow/Wispr Flow.app" /Applications/
          echo "Wispr Flow installed successfully"
        else
          echo "Warning: Could not find Wispr Flow.app in mounted DMG"
        fi

        # Unmount DMG
        hdiutil detach "/Volumes/Wispr Flow" -quiet 2>/dev/null || true

        # Cleanup
        rm -rf "$TEMP_DIR"
      else
        echo "Wispr Flow already installed"
      fi
    '';
  };
}
