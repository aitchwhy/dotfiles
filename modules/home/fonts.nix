# Nerd fonts configuration
# Provides programming fonts with icon glyphs for terminal/editor
{ config, lib, pkgs, ... }:

with lib;

{
  options.modules.home.fonts = {
    enable = mkEnableOption "nerd fonts for terminal/editor";
  };

  config = mkIf config.modules.home.fonts.enable {
    home.packages = with pkgs; [
      nerd-fonts.fira-code # Programming ligatures
      nerd-fonts.symbols-only # Just the icon glyphs
    ];
  };
}
