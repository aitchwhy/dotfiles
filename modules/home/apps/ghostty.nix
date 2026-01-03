# Ghostty terminal configuration
# Uses native home-manager programs.ghostty module
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.modules.home.apps.ghostty = {
    enable = mkEnableOption "ghostty terminal";
  };

  config = mkIf config.modules.home.apps.ghostty.enable {
    programs.ghostty = {
      enable = true;
      package = pkgs.ghostty-bin; # Pre-built binary for macOS, launch via Terminal/Raycast

      enableZshIntegration = true;
      enableBashIntegration = true;

      # Disable bat syntax to avoid "Dockerfile (with bash)" unresolved context warning
      # The ghostty syntax causes bat to rebuild its cache, breaking Dockerfile syntax dependencies
      installBatSyntax = false;

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
        theme = "TokyoNight Storm";
        window-theme = "system";
        window-padding-balance = true;
        font-family = "Fira Code Nerd Font";
        cursor-style = "bar";
        cursor-style-blink = true;
        cursor-color = "cell-foreground";
        bold-is-bright = true;

        # Colors (tokyonight-storm)
        background = "#24283b";
        foreground = "#c0caf5";
        selection-background = "#364a82";
        selection-foreground = "#c0caf5";
        cursor-text = "cell-background";

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
        # Using "detect" to let terminal multiplexers (Zellij) handle their own integration
        # Features:
        #   no-cursor,no-title: Prevent conflicts with Zellij's terminal management
        #   ssh-terminfo: Auto-install xterm-ghostty terminfo on SSH to new servers
        #   ssh-env: Fallback to xterm-256color if terminfo install fails
        shell-integration = "detect";
        shell-integration-features = "no-cursor,no-title,ssh-terminfo,ssh-env";

        # Keybinds
        keybind = [
          # Font zoom - must be explicit since defining keybinds can override defaults
          "cmd+equal=increase_font_size:1"
          "cmd+plus=increase_font_size:1"
          "cmd+minus=decrease_font_size:1"
          "cmd+zero=reset_font_size"

          # Equalize splits - use Cmd+Ctrl+= (Ghostty's default for this)
          "cmd+ctrl+equal=equalize_splits"

          # Window management
          "super+enter=toggle_fullscreen"

          # Shell prompt navigation
          "cmd+j=jump_to_prompt:1"
          "cmd+k=jump_to_prompt:-1"

          # Literal newline
          "shift+enter=text:\\n"
        ];
      };

      # Custom themes can be defined here
      # themes.tokyonight-storm already defined inline via color settings above
    };
  };
}
