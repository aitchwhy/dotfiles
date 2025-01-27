{ config, pkgs, username, useremail, ... }:

{
  programs.git = {
    enable = true;
    userName = "Hank Lee";
    userEmail = useremail;

    extraConfig = {
      # Basic settings
      init.defaultBranch = "main";
      pull.rebase = false;
      push.default = "simple";
      color.ui = true;

      # Core configuration
      core = {
        editor = "nvim";
        pager = "delta";
      };

      # Delta integration
      interactive.diffFilter = "delta --color-only";
      delta = {
        enable = true;
        options = {
          navigate = true;
          light = false;
          side-by-side = true;
          line-numbers = true;
        };
      };

      # Output formatting
      format.pretty = "%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset";

      # Credential management
      credential = {
        helper = "osxkeychain";
        "https://github.com".helper = "!/opt/homebrew/bin/gh auth git-credential";
        "https://gist.github.com".helper = "!/opt/homebrew/bin/gh auth git-credential";
      };

      # Diff and merge tools
      diff.tool = "vimdiff";
      merge.tool = "vimdiff";

      # Kaleidoscope integration
      difftool."Kaleidoscope" = {
        cmd = "ksdiff --partial-changeset --relative-path \"$MERGED\" -- \"$LOCAL\" \"$REMOTE\"";
      };
      mergetool."Kaleidoscope" = {
        cmd = "ksdiff --merge --output \"$MERGED\" --base \"$BASE\" -- \"$LOCAL\" --snapshot \"$REMOTE\" --snapshot";
        trustExitCode = true;
      };

      # LFS configuration
      filter.lfs = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };

      # Pager settings
      pager = {
        diff = "diff-so-fancy | less --tabs=1,5 -RFX";
        show = "diff-so-fancy | less --tabs=1,5 -RFX";
      };
    };

    # Global gitignore patterns
    ignores = [
      # Machine-specific
      "*.extra"

      # Compiled source
      "*.com" "*.class" "*.dll" "*.exe" "*.o" "*.so"

      # Packages
      "*.7z" "*.dmg" "*.iso" "*.rar" "*.zip"

      # Logs and databases
      "*.log" "*.sqlite"

      # OS generated files
      ".DS_Store" ".DS_Store?" "._*" ".Spotlight-V100" ".Trashes"
      "Desktop.ini" "ehthumbs.db" "Thumbs.db"
      ".idea" ".vagrant"

      # Environment
      ".env" "*.envrc" "*.env" ".direnv"

      # Development
      "node_modules/"
      ".python-version" "__pycache__/"

      # Tags
      "TAGS" ".TAGS" "!TAGS/"
      "tags" ".tags" "!tags/"
      "gtags.files" "GTAGS" "GRTAGS" "GPATH" "GSYMS"
      "cscope.files" "cscope.out" "cscope.in.out" "cscope.po.out"

      # Editor specific
      ".dir-locals.el"
      ".aider*"
    ];

    # Git aliases
    aliases = {
      # Basic commands
      st = "status";
      ci = "commit";
      co = "checkout";
      br = "branch";
      
      # Useful shortcuts
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      visual = "!gitk";
      
      # Log formatting
      lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      
      # Show changes
      staged = "diff --cached";
      both = "diff HEAD";
      
      # Branch management
      branch-name = "!git rev-parse --abbrev-ref HEAD";
      publish = "!git push -u origin $(git branch-name)";
      unpublish = "!git push origin :$(git branch-name)";
      cleanup = "!git branch --merged | grep -v '\\*\\|master\\|main\\|develop' | xargs -n 1 git branch -d";
      
      # Stash operations
      save = "stash save";
      pop = "stash pop";
      
      # Information display
      tags = "tag -l";
      branches = "branch -a";
      remotes = "remote -v";
    };
  };

  # Required Git-related packages
  home.packages = with pkgs; [
    git-lfs
    delta
    diff-so-fancy
    gh # GitHub CLI
  ];
}
