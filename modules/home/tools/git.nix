# Git configuration and tools
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
          # Essentials
          co = "checkout";
          br = "branch";
          ci = "commit";
          st = "status -sb";
          unstage = "reset HEAD --";
          last = "log -1 HEAD";

          # Logs
          lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
          ll = "log --pretty=format:'%C(yellow)%h%Cred%d %Creset%s%Cblue [%cn]' --decorate --numstat";
          lol = "log --graph --decorate --pretty=oneline --abbrev-commit";
          lola = "log --graph --decorate --pretty=oneline --abbrev-commit --all";

          # Workflow
          amend = "commit --amend --no-edit";
          fixup = "commit --fixup";
          squash = "commit --squash";
          undo = "reset --soft HEAD^";
          wip = ''commit -am "WIP" --no-verify'';

          # Diffs
          df = "diff";
          dc = "diff --cached";
          ds = "diff --stat";

          # Branch management
          brd = "branch -d";
          brD = "branch -D";
          bra = "branch -a";
          brm = "branch -m";

          # Remote operations
          pl = "pull";
          ps = "push";
          psu = "push -u origin HEAD";
          psf = "push --force-with-lease";

          # Stash
          ss = "stash save";
          sp = "stash pop";
          sl = "stash list";
          sa = "stash apply";

          # Misc
          contributors = "shortlog --summary --numbered";
          find = ''!f() { git log --all --grep="$1"; }; f'';
          aliases = "config --get-regexp alias";
        };

        init.defaultBranch = "main";
        commit.verbose = true;
        help.autocorrect = 1;

        core = {
          editor = "nvim";
          autocrlf = "input";
          whitespace = "space-before-tab,-indent-with-non-tab,trailing-space";
          preloadindex = true;
          fscache = true;
          untrackedcache = true;
        };

        fetch = {
          prune = true;
          pruneTags = true;
          parallel = 0;
        };

        pull = {
          rebase = true;
          autoStash = true;
        };

        push = {
          default = "current";
          followTags = true;
          autoSetupRemote = true;
        };

        rebase = {
          autoSquash = true;
          autoStash = true;
          backend = "merge";
        };

        merge = {
          conflictStyle = "zdiff3";
          tool = "nvimdiff";
          ff = "only";
        };

        diff = {
          algorithm = "histogram";
          renames = "copies";
          colorMoved = "default";
          colorMovedWS = "ignore-all-space";
          tool = "nvimdiff";
        };

        status = {
          submoduleSummary = true;
          showUntrackedFiles = "all";
        };

        branch = {
          autoSetupMerge = "always";
          sort = "-committerdate";
        };

        tag.sort = "version:refname";

        log = {
          showSignature = false;
          date = "iso";
        };

        rerere = {
          enabled = true;
          autoupdate = true;
        };

        credential.helper = "osxkeychain";
        protocol.version = 2;
        transfer.fsckobjects = true;
        receive.fsckObjects = true;
        maintenance = {
          auto = true;
          strategy = "incremental";
        };

        # SSH instead of HTTPS for GitHub/GitLab
        url = {
          "git@github.com:".insteadOf = "https://github.com/";
          "git@gitlab.com:".insteadOf = "https://gitlab.com/";
        };

        # Color customizations
        color = {
          ui = "auto";
          branch = {
            current = "yellow reverse";
            local = "yellow";
            remote = "green";
          };
          diff = {
            meta = "yellow bold";
            frag = "magenta bold";
            old = "red bold";
            new = "green bold";
          };
          status = {
            added = "green";
            changed = "yellow";
            untracked = "red";
          };
        };
      };
    };

    # Delta pager with full styling
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate = true;
        light = false;
        line-numbers = true;
        side-by-side = true;
        syntax-theme = "Monokai Extended";
        plus-style = "syntax #003800";
        minus-style = "syntax #3f0001";
        commit-decoration-style = "bold yellow box ul";
        file-style = "bold yellow ul";
        file-decoration-style = "none";
        hunk-header-decoration-style = "blue box";
        hunk-header-file-style = "red";
        hunk-header-line-number-style = "#067a00";
        hunk-header-style = "file line-number syntax";
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
