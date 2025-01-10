# home/home.nix
{ config, pkgs, ... }: {
  home = {
    username = "hank";
    homeDirectory = "/Users/hank";  # This needs to be explicitly set
    stateVersion = "23.11";  # Check this matches your nix version
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Package installations
  home.packages = with pkgs; [
    ripgrep
    fd
    tree
    htop
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "aitchwhy";
    userEmail = "hank.lee.qed@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # Shell configuration (zsh example)
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ls = "ls --color=auto";
      ll = "ls -la";
      ".." = "cd ..";
    };
  };
}