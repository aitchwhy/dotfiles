# home/home.nix
{ config, pkgs, ... }: {


  home = {
    # Home Manager needs a bit of information about you and the
    # paths it should manage.
    username = "hank";
    homeDirectory = "/Users/hank";  # This needs to be explicitly set

    # The state version is required and should stay at the version you
    # originally installed.

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "24.11";

    # Package installations
    packages = with pkgs; [
      vim
      git
      curl
    ];
  };

  # Let Home Manager manage itself

  programs = {
    # Shell configuration (zsh example)
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        ls = "ls --color=auto";
        ll = "ls -la";
        ".." = "cd ..";


      };
    };
    # Git configuration
    git = {
      enable = true;
      userName = "aitchwhy";
      userEmail = "hank.lee.qed@gmail.com";
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
      };
    };
  };

  
}
