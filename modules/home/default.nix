# Home Manager module aggregator
{ lib, ... }:
let
  inherit (lib) mkDefault;
in
{
  imports = [
    # Packages (platform-aware, DRY)
    ./packages

    # Shell
    ./shell/zsh.nix
    ./shell/bash.nix
    ./shell/starship.nix
    ./shell/aliases.nix

    # Tools
    ./tools/git.nix
    ./tools/git-hooks.nix
    ./tools/development.nix
    ./tools/atuin.nix
    ./tools/direnv.nix
    ./tools/bat.nix
    ./tools/fzf.nix
    ./tools/htop.nix
    ./tools/yazi.nix
    ./tools/zellij.nix
    ./tools/nixbuild.nix

    # Editors
    ./editors/neovim.nix

    # Fonts
    ./fonts.nix

    # Apps (xdg.configFile based)
    ./apps/ghostty.nix
    ./apps/kanata.nix
    ./apps/bartender.nix
    ./apps/raycast.nix
    ./apps/claude.nix
    ./apps/cursor.nix
    ./apps/misc.nix
    ./apps/keyboard-layout.nix
    ./apps/homerow.nix
    ./apps/betterdisplay.nix
    ./apps/default-apps.nix
    ./apps/paste.nix

    # Third-party apps (targets.darwin.defaults)
    ./apps/fantastical.nix
    ./apps/zoom.nix
    ./apps/spotify.nix
    ./apps/chrome.nix
    ./apps/slack.nix
    ./apps/obsidian.nix
  ];

  config = {
    programs.home-manager.enable = true;
    home.stateVersion = mkDefault "26.05"; # Bleeding edge

    # Disable manual generation to avoid builtins.toFile warning
    # See: https://github.com/nix-community/home-manager/issues/7935
    manual.manpages.enable = false;

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
        git-hooks.enable = mkDefault true;
        development.enable = mkDefault true;
        atuin.enable = mkDefault true;
        direnv.enable = mkDefault true;
        bat.enable = mkDefault true;
        fzf.enable = mkDefault true;
        htop.enable = mkDefault true;
        yazi.enable = mkDefault true;
        zellij.enable = mkDefault true;
        nixbuild.enable = mkDefault false; # Requires SSH key setup
      };

      editors = {
        neovim.enable = mkDefault true;
      };

      fonts.enable = mkDefault true;

      apps = {
        ghostty.enable = mkDefault true;
        kanata.enable = mkDefault true;
        bartender.enable = mkDefault true;
        raycast.enable = mkDefault true;
        claude.enable = mkDefault true;

        cursor.enable = mkDefault true;
        misc.enable = mkDefault true;
        keyboardLayout.enable = mkDefault true;
        homerow.enable = mkDefault true;
        betterdisplay.enable = mkDefault true;
        defaultApps.enable = mkDefault true;
        paste.enable = mkDefault true;

        # Third-party apps
        fantastical.enable = mkDefault true;
        zoom.enable = mkDefault true;
        spotify.enable = mkDefault true;
        chrome.enable = mkDefault true;
        slack.enable = mkDefault true;
        obsidian.enable = mkDefault true;
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
      FLAKE = "$HOME/dotfiles"; # For NH (Nix Helper)
      CFS = "$HOME/dotfiles/config";
      CFSZSH = "$HOME/dotfiles/config/zsh";
      CMD = "$HOME/dotfiles/scripts";
      OBS = "$HOME/obsidian/primary";
      GLOBAL_JUSTFILE = "$HOME/dotfiles/justfile";

      # Tool config paths
      LG_CONFIG_FILE = "$HOME/dotfiles/config/git/lazygit.yml";
      ATUIN_CONFIG_DIR = "$HOME/dotfiles/config/atuin";
      YAZI_CONFIG_DIR = "$HOME/dotfiles/config/yazi";

      # Secrets management (sops-nix)
      SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";
      ZELLIJ_CONFIG_DIR = "$HOME/dotfiles/config/zellij";

      # Claude Code LSP support
      ENABLE_LSP_TOOL = "1";

      # FZF options are set in modules/home/tools/fzf.nix

      # Colors
      COLORTERM = "truecolor";
      BAT_THEME = "TwoDark";
    };
  };
}
