# Shell completions SSOT integration
# Adds generated completions from config/completions/ to shell fpath
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  # Runtime path to generated completions (not Nix path - files are gitignored)
  completionsDir = "${config.home.homeDirectory}/dotfiles/config/completions/generated";
in
{
  options.modules.home.shell.completions = {
    enable = mkEnableOption "SSOT-managed shell completions";
  };

  config = mkIf config.modules.home.shell.completions.enable {
    # Add generated zsh completions to fpath
    programs.zsh.initContent = lib.mkBefore ''
      # SSOT-generated completions (from config/completions/generated/zsh)
      if [[ -d "${completionsDir}/zsh" ]]; then
        fpath=("${completionsDir}/zsh" $fpath)
      fi
    '';

    # Source generated bash completions
    programs.bash.initExtra = lib.mkAfter ''
      # SSOT-generated completions (from config/completions/generated/bash)
      if [[ -d "${completionsDir}/bash" ]]; then
        for f in "${completionsDir}"/bash/*.bash; do
          [[ -f "$f" ]] && source "$f"
        done
      fi
    '';
  };
}
