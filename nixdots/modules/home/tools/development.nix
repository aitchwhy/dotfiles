# Development tools configuration
{ config, lib, pkgs, ... }:

with lib;

{
  options.modules.home.tools.development = {
    enable = mkEnableOption "development tools";

    enableDirectoryEnv = mkOption {
      type = types.bool;
      default = true;
      description = "Enable direnv for directory-specific environments";
    };

    enableModernCli = mkOption {
      type = types.bool;
      default = true;
      description = "Enable modern CLI replacements";
    };
  };

  config = mkIf config.modules.home.tools.development.enable {
    # Directory environment management
    programs.direnv = mkIf config.modules.home.tools.development.enableDirectoryEnv {
      enable = true;
      nix-direnv.enable = true;
      silent = true;
    };

    # Fuzzy finder
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultOptions = [
        "--height 40%"
        "--border sharp"
        "--layout reverse"
        "--info inline"
        "--preview-window=:hidden"
        "--bind='ctrl-/:toggle-preview'"
      ];
    };

    # Modern file manager
    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
    };

    # Smart directory jumping
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ "--cmd cd" ];
    };

    # Modern Unix replacements
    programs.eza = mkIf config.modules.home.tools.development.enableModernCli {
      enable = true;
      enableZshIntegration = true;
      git = true;
      icons = true;
      extraOptions = [
        "--group-directories-first"
        "--header"
      ];
    };

    programs.bat = mkIf config.modules.home.tools.development.enableModernCli {
      enable = true;
      config = {
        theme = "TwoDark";
        pager = "less -FR";
      };
    };

    # Shell integration
    programs.nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

    # Modern shell history
    programs.atuin = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      settings = {
        auto_sync = true;
        sync_frequency = "5m";
        search_mode = "fuzzy";
        style = "compact";
      };
    };

    # Core CLI tools
    home.packages = with pkgs; [
      # Essential CLI tools
      just

      # Modern Unix replacements
      ripgrep # Better grep
      fd # Better find
      delta # Better diff
      sd # Better sed
      dust # Better du
      procs # Better ps
      bottom # Better top

      # Data processing
      jq # JSON processor
      yq # YAML processor

      # System monitoring
      htop
      btop
      ncdu
      tree

      # Network tools
      wget
      curl

      # File management
      watchman # File watcher
    ];
  };
}
