# FZF fuzzy finder configuration
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.modules.home.tools.fzf = {
    enable = mkEnableOption "fzf fuzzy finder";
  };

  config = mkIf config.modules.home.tools.fzf.enable {
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;

      defaultCommand = "fd --type f --hidden --follow --exclude .git";
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
        "--cycle"
        "--marker='✓'"
        "--bind=ctrl-j:down,ctrl-k:up"
      ];

      fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
      fileWidgetOptions = [ "--preview 'bat --style=numbers --color=always {}'" ];

      changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
      changeDirWidgetOptions = [ "--preview 'eza --tree --level=2 --icons {}'" ];

      historyWidgetOptions = [
        "--sort"
        "--exact"
      ];
    };
  };
}
