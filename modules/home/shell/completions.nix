# Shell completions SSOT integration
# Adds generated completions from config/completions/ to shell fpath
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  # Path to generated completions (relative to dotfiles root)
  completionsDir = ../../../config/completions/generated;
in
{
  options.modules.home.shell.completions = {
    enable = mkEnableOption "SSOT-managed shell completions";
  };

  config = mkIf config.modules.home.shell.completions.enable {
    # Add generated zsh completions to fpath
    programs.zsh.initContent = lib.mkBefore ''
      # SSOT-generated completions (from config/completions/generated/zsh)
      fpath=(${completionsDir}/zsh $fpath)
    '';

    # Source generated bash completions
    programs.bash.initExtra = lib.mkAfter ''
      # SSOT-generated completions (from config/completions/generated/bash)
      for f in ${completionsDir}/bash/*.bash; do
        [[ -f "$f" ]] && source "$f"
      done
    '';
  };
}
