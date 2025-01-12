{ config, lib, pkgs, ... }:

{
  programs.zellij = {
    enable = true;
    enableZshIntegration = true;

    # Link the existing configuration
    settings = {
      # Load the configuration from the existing file
      configPath = "${config.xdg.configHome}/zellij/config.kdl";
    };
  };

  # Link configuration files
  xdg.configFile = {
    "zellij/config.kdl" = {
      source = ../../modules/zellij/config.kdl;
    };

    # Add layouts directory
    "zellij/layouts" = {
      source = ../../modules/zellij/layouts;
      recursive = true;
    };
  };

  # Shell aliases
  programs.zsh.shellAliases = {
    zj = "zellij";
    zja = "zellij attach";
    zjl = "zellij list-sessions";
    zjk = "zellij kill-session";
  };

  # Environment variables
  home.sessionVariables = {
    # Set default terminal multiplexer
    ZELLIJ_AUTO_ATTACH = "true";
    ZELLIJ_AUTO_EXIT = "true";
  };

  # Additional packages that might be needed
  home.packages = with pkgs; [
    # Terminal utilities that work well with Zellij
    tmux # As fallback
    terminal-notifier # For notifications
  ];

  # Shell integration
  programs.zsh.initExtra = ''
    # Zellij shell integration
    if [[ -n "$ZELLIJ" ]]; then
      # We're inside Zellij
      # Add any Zellij-specific configuration here
      :
    else
      # We're not in Zellij
      # Auto-attach to last session or create new one
      if [[ -z "$ZELLIJ_AUTO_START" && "$TERM_PROGRAM" != "vscode" ]]; then
        if [[ -z "$ZELLIJ_AUTO_ATTACH" ]]; then
          zellij
        else
          zellij attach -c
        fi
      fi
    fi
  '';
}
