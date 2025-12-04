# Default application handlers
# Uses duti to set file type associations declaratively
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.modules.home.apps.defaultApps = {
    enable = mkEnableOption "default application handlers";
  };

  config = mkIf config.modules.home.apps.defaultApps.enable {
    home.packages = [pkgs.duti];

    # Set default apps after packages are installed
    home.activation.setDefaultApps = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # PDF Expert for PDFs
      if [ -d "/Applications/PDF Expert.app" ]; then
        $DRY_RUN_CMD ${pkgs.duti}/bin/duti -s com.readdle.PDFExpert-Mac .pdf all
        echo "Set PDF Expert as default PDF handler"
      fi
    '';
  };
}
