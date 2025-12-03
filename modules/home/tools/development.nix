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

    # Smart directory jumping (standard z/zi behavior)
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = []; # Standard: z for jump, zi for interactive
    };

    # Modern Unix replacements
    programs.eza = mkIf config.modules.home.tools.development.enableModernCli {
      enable = true;
      enableZshIntegration = true;
      git = true;
      icons = "auto";
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
      hexyl # Binary hex viewer (for Yazi previews)
      ouch # Archive tool (for Yazi previews)

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
