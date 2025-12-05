# Git configuration and tools
{ config, lib, pkgs, ... }:

with lib;

{
  options.modules.home.tools.git = {
    enable = mkEnableOption "Git configuration";

    userName = mkOption {
      type = types.str;
      description = "Git user name";
    };

    userEmail = mkOption {
      type = types.str;
      description = "Git user email";
    };

    signing = {
      enable = mkEnableOption "Git commit signing";

      key = mkOption {
        type = types.str;
        default = "";
        description = "GPG key for signing";
      };
    };
  };

  config = mkIf config.modules.home.tools.git.enable {
    programs.git = {
      enable = true;
      lfs.enable = true;

      signing = mkIf config.modules.home.tools.git.signing.enable {
        key = config.modules.home.tools.git.signing.key;
        signByDefault = true;
      };

      ignores = [
        ".DS_Store"
        "*.swp"
        "*.swo"
        "*~"
        ".env.local"
        ".direnv"
        "node_modules"
        "target"
        "dist"
        ".idea"
        ".vscode"
        "*.log"
      ];

      settings = {
        user = {
          name = config.modules.home.tools.git.userName;
          email = config.modules.home.tools.git.userEmail;
        };

        alias = {
          co = "checkout";
          br = "branch";
          ci = "commit";
          st = "status";
          unstage = "reset HEAD --";
          last = "log -1 HEAD";
          l = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        };

        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        merge.conflictStyle = "zdiff3";
        rerere.enabled = true;
        branch.sort = "-committerdate";
        credential.helper = "osxkeychain";

        core = {
          preloadindex = true;
          fscache = true;
          untrackedcache = true;
        };

        diff = {
          algorithm = "histogram";
          colorMoved = "default";
          colorMovedWS = "ignore-all-space";
        };
      };
    };

    # Delta is now a separate program in home-manager
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate = true;
        light = false;
        line-numbers = true;
        side-by-side = true;
      };
    };

    # Additional Git tools
    home.packages = with pkgs; [
      lazygit
      commitizen
      lefthook
    ];
  };
}
