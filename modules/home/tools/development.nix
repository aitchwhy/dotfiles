# Development tools configuration
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
in
{
  options.modules.home.tools.development = {
    enable = mkEnableOption "development tools";

    enableModernCli = mkOption {
      type = types.bool;
      default = true;
      description = "Enable modern CLI replacements (eza)";
    };
  };

  config = mkIf config.modules.home.tools.development.enable {
    # Note: direnv, fzf, bat, yazi, and htop have dedicated modules in tools/
    # This module provides zoxide, eza, nix-index and dev packages

    # Smart directory jumping (standard z/zi behavior)
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ ]; # Standard: z for jump, zi for interactive
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

    # Shell integration
    programs.nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

    # Core CLI tools
    home.packages = with pkgs; [
      # Essential CLI tools
      just
      act

      # Node.js version management (fnm for per-project .node-version)
      fnm

      # NH - Modern Nix Helper (nh darwin switch, nh clean)
      nh

      # Modern Unix replacements
      ripgrep # Better grep
      fd # Better find
      sd # Better sed
      dust # Better du
      hexyl # Binary hex viewer (for Yazi previews)
      ouch # Archive tool (for Yazi previews)

      # AST-based code search (required by ast-grep MCP server)
      ast-grep

      # Data processing
      jq # JSON processor
      yq # YAML processor

      # System monitoring (htop has dedicated module with custom settings)
      btop
      ncdu

      # Network & API tools (SOTA Jan 2026 - see ADR-009)
      wget
      curl
      ookla-speedtest # Internet speed testing
      trippy # Network path (replaces mtr + traceroute + ping)
      rustscan # Port scanning (10x faster than nmap)
      bandwhich # Per-process bandwidth monitor
      termshark # TUI Wireshark
      xh # HTTP client (Rust, replaces httpie)

      # File management
      watchman # File watcher
    ];
  };
}
