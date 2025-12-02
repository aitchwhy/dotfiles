# Home Manager module aggregator
{ config, lib, ... }:

with lib;

{
  imports = [
    # Shell components
    ./shell/zsh.nix
    ./shell/bash.nix
    ./shell/prompts.nix
    ./shell/aliases.nix

    # Development tools
    ./tools/git.nix
    ./tools/tmux.nix
    ./tools/development.nix

    # Editors
    ./editors/neovim.nix
  ];

  # Enable modules by default
  config = {
    # Core home-manager settings
    programs.home-manager.enable = true;
    home.stateVersion = "24.11";

    # Enable all modules
    modules.home = {
      shell = {
        zsh.enable = mkDefault true;
        bash.enable = mkDefault true;
        prompts.enable = mkDefault true;
        aliases.enable = mkDefault true;
      };

      tools = {
        git = {
          enable = mkDefault true;
          # User must provide userName and userEmail
        };
        tmux.enable = mkDefault true;
        development.enable = mkDefault true;
      };

      editors = {
        neovim.enable = mkDefault true;
      };
    };

    # Environment variables
    home.sessionVariables = {
      PAGER = "less -FR";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";

      # Development
      HOMEBREW_NO_ANALYTICS = "1";
      DOTNET_CLI_TELEMETRY_OPTOUT = "1";
      GATSBY_TELEMETRY_DISABLED = "1";
      NEXT_TELEMETRY_DISABLED = "1";

      # Performance
      DIRENV_LOG_FORMAT = "";

      # Better defaults
      LESS = "-FR";
      SYSTEMD_LESS = "-FR";
    };
  };
}
