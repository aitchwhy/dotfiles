# Linux-only packages
# These packages are Linux-specific clipboard utilities
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.modules.home.packages;
in {
  config = mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = with pkgs; [
      # Clipboard support
      xclip # X11 clipboard
      wl-clipboard # Wayland clipboard
    ];
  };
}
