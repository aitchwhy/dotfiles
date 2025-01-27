{ config, lib, pkgs, ... }:

{
  # Install cheat
  home.packages = with pkgs; [
    cheat
  ];

  # Link cheat configuration
  xdg.configFile = {
    "cheat/conf.yml" = {
      source = ../../modules/cheat/conf.yml;
    };
  };

  # Environment variables
  home.sessionVariables = {
    CHEAT_CONFIG_PATH = "${config.xdg.configHome}/cheat/conf.yml";
    CHEAT_USE_FZF = "true";
  };

  # Shell integration
  programs.zsh.initExtra = ''
    # Cheat shell integration
    if command -v cheat >/dev/null 2>&1; then
      # Enable fzf integration if available
      if command -v fzf >/dev/null 2>&1; then
        export CHEAT_USE_FZF=true
      fi
    fi
  '';

  # Shell aliases
  programs.zsh.shellAliases = {
    # Quick access to personal cheatsheets
    "ch" = "cheat";
    "cht" = "cheat --edit";
  };
}
