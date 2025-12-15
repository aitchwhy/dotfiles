# Obsidian note-taking app configuration
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg = config.modules.home.apps.obsidian;
in
{
  options.modules.home.apps.obsidian = {
    enable = mkEnableOption "Obsidian settings";
  };

  config = mkIf cfg.enable {
    targets.darwin.defaults."md.obsidian" = {
      # Obsidian settings are stored in vault .obsidian folders
      # This module tracks that the app is managed
    };
  };
}
