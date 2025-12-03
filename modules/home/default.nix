# Home Manager module aggregator
{ config, lib, ... }:

with lib;

{
  imports = [
    # Shell
    ./shell/zsh.nix
    ./shell/bash.nix
    ./shell/starship.nix
    ./shell/aliases.nix

    # Tools
    ./tools/git.nix
    ./tools/tmux.nix
    ./tools/development.nix
    ./tools/atuin.nix
    ./tools/direnv.nix
    ./tools/bat.nix
    ./tools/fzf.nix
    ./tools/htop.nix
    ./tools/yazi.nix
    ./tools/zellij.nix

    # Editors
    ./editors/neovim.nix

    # Apps (xdg.configFile based)
    ./apps/aerospace.nix
    ./apps/ghostty.nix
    ./apps/karabiner.nix
    ./apps/hammerspoon.nix
    ./apps/misc.nix
  ];

  config = {
    programs.home-manager.enable = true;
    home.stateVersion = mkDefault "25.05";

    # Enable all modules by default
    modules.home = {
      shell = {
        zsh.enable = mkDefault true;
        bash.enable = mkDefault true;
        starship.enable = mkDefault true;
        aliases.enable = mkDefault true;
      };

      tools = {
        git.enable = mkDefault true;
        tmux.enable = mkDefault true;
        development.enable = mkDefault true;
        atuin.enable = mkDefault true;
        direnv.enable = mkDefault true;
        bat.enable = mkDefault true;
        fzf.enable = mkDefault true;
        htop.enable = mkDefault true;
        yazi.enable = mkDefault true;
        zellij.enable = mkDefault true;
      };

      editors = {
        neovim.enable = mkDefault true;
      };

      apps = {
        aerospace.enable = mkDefault true;
        ghostty.enable = mkDefault true;
        karabiner.enable = mkDefault true;
        hammerspoon.enable = mkDefault true;
        misc.enable = mkDefault true;
      };
    };

    # Environment variables
    home.sessionVariables = {
      # Pagers
      PAGER = "less -FR";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      LESS = "-FR";

      # Telemetry opt-out
      HOMEBREW_NO_ANALYTICS = "1";
      DOTNET_CLI_TELEMETRY_OPTOUT = "1";
      GATSBY_TELEMETRY_DISABLED = "1";
      NEXT_TELEMETRY_DISABLED = "1";
      DIRENV_LOG_FORMAT = "";

      # Path shortcuts
      DOTFILES = "$HOME/dotfiles";
      CFS = "$HOME/dotfiles/config";
      CFSZSH = "$HOME/dotfiles/config/zsh";
      CMD = "$HOME/dotfiles/scripts";
      OBS = "$HOME/obsidian/primary";
      GLOBAL_JUSTFILE = "$HOME/dotfiles/justfile";

      # Tool config paths
      LG_CONFIG_FILE = "$HOME/dotfiles/config/git/lazygit.yml";
      STARSHIP_CONFIG = "$HOME/dotfiles/config/starship/starship.toml";
      ATUIN_CONFIG_DIR = "$HOME/dotfiles/config/atuin";
      YAZI_CONFIG_DIR = "$HOME/dotfiles/config/yazi";
      ZELLIJ_CONFIG_DIR = "$HOME/dotfiles/config/zellij";

      # FZF options are set in modules/home/tools/fzf.nix

      # Colors
      COLORTERM = "truecolor";
      BAT_THEME = "TwoDark";
    };
  };
}
