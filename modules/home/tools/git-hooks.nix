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
    enable = mkEnableOption "git hooks documentation";
  };

  config = mkIf config.modules.home.tools.git-hooks.enable {
    # REMOVED: programs.git.settings.core.hooksPath
    # Global hooks bypass project ignores, causing false positives.
    # Each project uses local lefthook with project-specific rules.

    # Explicitly unset any inherited value
    programs.git.settings.core.hooksPath = "";

    home.file.".config/git/HOOKS.md".text = ''
      # Git Hooks Architecture

      **Global hooks are disabled by design.**

      Each project uses local lefthook with project-specific rules.
      Run `lefthook install` in each project.

      See: ~/dotfiles/config/quality/rules/templates/README.md
    '';
  };
}
