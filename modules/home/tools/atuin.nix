# Atuin shell history configuration
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.modules.home.tools.atuin = {
    enable = mkEnableOption "atuin shell history";
  };

  config = mkIf config.modules.home.tools.atuin.enable {
    xdg.configFile."atuin/themes/catppuccin-mocha-lavender.toml".text = ''
      [theme]
      name = "catppuccin-mocha-lavender"

      [colors]
      AlertInfo = "#a6e3a1"
      AlertWarn = "#fab387"
      AlertError = "#f38ba8"
      Annotation = "#b4befe"
      Base = "#cdd6f4"
      Guidance = "#9399b2"
      Important = "#f38ba8"
      Title = "#b4befe"
    '';

    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;

      settings = {
        auto_sync = true;
        sync_frequency = "60m";
        workspaces = true;
        update_check = true;

        search_mode = "fuzzy";
        filter_mode = "global";
        filter_mode_shell_up_key_binding = "directory";
        search_mode_shell_up_key_binding = "fuzzy";

        style = "compact";
        inline_height = 40;
        show_preview = true;
        max_preview_height = 4;
        scroll_context_lines = 3;

        enter_accept = false;
        keymap_mode = "auto";
        keymap_cursor = {
          emacs = "blink-block";
          vim_insert = "blink-block";
          vim_normal = "steady-block";
        };

        common_subcommands = [
          "brew"
          "cargo"
          "docker"
          "git"
          "go"
          "ip"
          "kubectl"
          "tldr"
          "nix"
          "npm"
          "pnpm"
          "bun"
          "zellij"
          "yarn"
        ];

        common_prefix = [ "sudo" ];

        sync.records = true;
        theme.name = "catppuccin-mocha-lavender";
      };
    };
  };
}
