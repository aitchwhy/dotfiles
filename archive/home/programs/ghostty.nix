{ config, lib, pkgs, ... }:

{
  # Link Ghostty configuration
  home.file = {
    ".config/ghostty/config" = {
      source = ../../modules/ghostty/config;
      onChange = "pkill -USR1 ghostty || true"; # Reload Ghostty on config change
    };
  };

  # Install themes
  xdg.configFile = {
    "ghostty/themes" = {
      source = pkgs.fetchFromGitHub {
        owner = "ghostty";
        repo = "themes";
        rev = "main";
        sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Replace with actual hash
      };
      recursive = true;
    };
  };

  # Environment variables
  home.sessionVariables = {
    # Set default terminal
    TERMINAL = "ghostty";
  };

  # Additional packages that might be needed
  home.packages = with pkgs; [
    # Terminal utilities that work well with Ghostty
    tmux # Terminal multiplexer
    zellij # Alternative terminal multiplexer
    terminal-notifier # For notifications
  ];

  # Shell integration
  programs.zsh.initExtra = ''
    # Ghostty shell integration
    if [ "$TERM" = "xterm-ghostty" ]; then
      source "${config.home.homeDirectory}/.config/ghostty/shell-integration/zsh"
    fi
  '';

  # Default settings (these will be merged with the config file)
  programs.ghostty = {
    enable = true;
    settings = {
      # General
      theme = "catppuccin-frappe";
      "auto-update" = "download";
      "font-size" = 12;
      fullscreen = false;
      "macos-option-as-alt" = true;
      "macos-non-native-fullscreen" = true;
      "window-save-state" = "always";
      "window-inherit-working-directory" = true;
      "confirm-close-surface" = false;
      "mouse-hide-while-typing" = false;
      "clipboard-read" = "allow";
      "clipboard-write" = "allow";

      # Window Appearance
      "window-decoration" = false;
      "window-padding-x" = 12;
      "window-padding-y" = 12;

      # Cursor Settings
      "cursor-style" = "block";
      "cursor-style-blink" = false;

      # Quick Terminal Settings
      "quick-terminal-position" = "center";
      "quick-terminal-screen" = "main";
      "quick-terminal-animation-duration" = 0;

      # Shell Integration
      "shell-integration" = "zsh";
      "shell-integration-features" = "cursor";

      # Keybindings
      keybind = [
        "cmd+comma=open_config"
        "cmd+shift+comma=reload_config"
        "cmd+opt+i=inspector:toggle"
        "cmd+enter=toggle_fullscreen"
        "global:cmd+=toggle_quick_terminal"
        "cmd+period=toggle_quick_terminal"
      ];
    };
  };
}
