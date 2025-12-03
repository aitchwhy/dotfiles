# Ghostty terminal configuration
# Uses native home-manager programs.ghostty module
{ config, lib, pkgs, ... }:

with lib;

{
  options.modules.home.apps.ghostty = {
    enable = mkEnableOption "ghostty terminal";
  };

  config = mkIf config.modules.home.apps.ghostty.enable {
    programs.ghostty = {
      enable = true;
      package = null; # Installed via Homebrew cask, not nixpkgs

      enableZshIntegration = true;
      enableBashIntegration = true;

      settings = {
        # System behavior
        auto-update = "download";
        window-save-state = "always";
        confirm-close-surface = false;
        macos-non-native-fullscreen = true;
        macos-option-as-alt = true;
        link-url = true;
        mouse-hide-while-typing = true;

        # Window settings
        maximize = true;
        fullscreen = false;

        # Appearance
        theme = "tokyonight-storm";
        window-theme = "system";
        window-padding-balance = true;
        font-family = "Fira Code Nerd Font";
        cursor-style = "bar";
        cursor-style-blink = true;
        cursor-invert-fg-bg = true;
        bold-is-bright = true;

        # Colors (tokyonight-storm)
        background = "#24283b";
        foreground = "#c0caf5";
        selection-background = "#364a82";
        selection-foreground = "#c0caf5";
        cursor-color = "#c0caf5";
        cursor-text = "#1d202f";

        # Clipboard
        clipboard-read = "allow";
        clipboard-write = "allow";
        copy-on-select = true;

        # Quick terminal
        quick-terminal-position = "center";
        quick-terminal-screen = "main";
        quick-terminal-animation-duration = 0;
        quick-terminal-autohide = true;

        # Shell integration
        shell-integration = "zsh";
        shell-integration-features = "cursor,title";

        # Keybinds
        keybind = [
          "cmd+equal=equalize_splits"
          "super+enter=toggle_fullscreen"
          "cmd+j=jump_to_prompt:1"
          "cmd+k=jump_to_prompt:-1"
          "shift+enter=text:\\n"
        ];
      };

      # Custom themes can be defined here
      # themes.tokyonight-storm already defined inline via color settings above
    };
  };
}
