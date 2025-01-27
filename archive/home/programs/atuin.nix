{ config, pkgs, ... }:

{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;

    flags = [
      "--disable-up-arrow"
    ];

    settings = {
      # General settings
      auto_sync = true;
      sync_frequency = "5m";
      sync_address = "https://api.atuin.sh";
      search_mode = "fuzzy";

      # UI settings
      style = "full";
      show_preview = true;
      inline_height = 30;
      
      # Filter settings
      filter_mode = "global";
      filter_mode_shell_up_key_binding = "directory";

      # History settings
      history_filter = [
        "^secret"
        "^password"
        "^token"
        "^api[_-]key"
        "^aws_"
        "^export.*="
      ];

      # Key bindings
      key_binding_mode = "vim";
      enter_accept = true;

      # Database settings
      db_path = "${config.xdg.dataHome}/atuin/history.db";

      # Update settings
      update_check = false;

      # Search settings
      search = {
        mode = "fuzzy";
        filter_mode = "global";
      };

      # Sync settings
      sync = {
        records = true;
        auto = true;
      };
    };
  };

  # Additional configuration files
  xdg.configFile = {
    "atuin/key-binding.bash" = {
      text = ''
        # Custom key bindings for Atuin
        bind '"\C-r": "\C-a atuin search -i -- \C-e"'
        bind '"\e[A": "\C-a atuin search -i -- \C-e"'
      '';
    };
  };

  # Environment variables
  home.sessionVariables = {
    ATUIN_NOBIND = "true";
    ATUIN_HISTORY_SIZE = "100000";
  };
}
