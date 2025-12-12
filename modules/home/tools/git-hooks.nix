# Global git hooks directory setup
# Lefthook manages actual hook files; this just sets the global path
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.modules.home.tools.git-hooks = {
    enable = mkEnableOption "global git hooks path";
  };

  config = mkIf config.modules.home.tools.git-hooks.enable {
    # Set global hooks path - lefthook will install hooks here
    programs.git.settings.core.hooksPath = "${config.home.homeDirectory}/.config/git/hooks";

    # Ensure hooks directory exists
    home.file.".config/git/hooks/.keep" = {
      text = "# Hooks managed by lefthook - run 'lefthook install' in each repo\n";
    };
  };
}
