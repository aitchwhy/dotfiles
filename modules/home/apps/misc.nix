# Miscellaneous application configurations
# For tools without native home-manager support
{ config, lib, ... }:

with lib;

{
  options.modules.home.apps.misc = {
    enable = mkEnableOption "miscellaneous app configs";
  };

  config = mkIf config.modules.home.apps.misc.enable {
    xdg.configFile = {
      "aider".source = ../../../config/aider;
      "lazydocker".source = ../../../config/lazydocker;
      "httpie".source = ../../../config/httpie;
      "just".source = ../../../config/just;
      "glow".source = ../../../config/glow;
      "repomix".source = ../../../config/repomix;
      "tree-sitter".source = ../../../config/tree-sitter;
      "hazel".source = ../../../config/hazel;
      "cursor".source = ../../../config/cursor;
    };
  };
}
