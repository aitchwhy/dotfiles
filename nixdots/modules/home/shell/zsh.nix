# Zsh shell configuration
{ config, lib, ... }:

with lib;

{
  options.modules.home.shell.zsh = {
    enable = mkEnableOption "Zsh shell configuration";
  };

  config = mkIf config.modules.home.shell.zsh.enable {
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      enableCompletion = true;

      initExtra = ''
        # Fast directory navigation
        setopt AUTO_CD
        setopt AUTO_PUSHD
        setopt PUSHD_IGNORE_DUPS
        setopt PUSHD_SILENT

        # Better history
        setopt HIST_IGNORE_ALL_DUPS
        setopt HIST_FIND_NO_DUPS
        setopt HIST_SAVE_NO_DUPS
        setopt SHARE_HISTORY

        # Modern completions
        setopt MENU_COMPLETE
        setopt AUTO_LIST
        setopt COMPLETE_IN_WORD
      '';

      history = {
        size = 50000;
        save = 50000;
        ignoreDups = true;
        ignoreSpace = true;
        share = true;
      };
    };
  };
}
