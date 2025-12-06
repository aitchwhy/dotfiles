# AeroSpace tiling window manager
# https://github.com/nikitabobko/AeroSpace
#
# AeroSpace provides keyboard-driven window tiling:
#   - Alt + hjkl: Focus navigation
#   - Alt+Shift + hjkl: Window movement
#   - Alt + 1-9: Workspace switching
#   - Alt + f: Toggle fullscreen
#
# Trackpad gestures are handled by Swish (not AeroSpace)
{ config, lib, ... }:

with lib;

let
  cfg = config.modules.home.apps.aerospace;
in
{
  options.modules.home.apps.aerospace = {
    enable = mkEnableOption "AeroSpace tiling window manager";
  };

  config = mkIf cfg.enable {
    # AeroSpace config location: ~/.config/aerospace/aerospace.toml
    xdg.configFile."aerospace/aerospace.toml".source = ../../../config/aerospace/aerospace.toml;
  };
}
