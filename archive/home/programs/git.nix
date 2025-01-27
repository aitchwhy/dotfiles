{ config, pkgs, username, useremail, ... }:

{
  programs.git = {
    enable = true;
    
    userName = "Hank Lee";
    userEmail = "hank.lee.qed@gmail.com";

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      push.default = "simple";
      
      core = {
        editor = "nvim";
        pager = "delta";
      };

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

      color.ui = true;

      format.pretty = "%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset";

      credential = {
        helper = "osxkeychain";
        "https://github.com".helper = "!/opt/homebrew/bin/gh auth git-credential";
        "https://gist.github.com".helper = "!/opt/homebrew/bin/gh auth git-credential";
      };

      diff = {
        tool = "vimdiff";
      };

      merge = {
        tool = "vimdiff";
      };

      difftool."Kaleidoscope" = {
        cmd = "ksdiff --partial-changeset --relative-path \"$MERGED\" -- \"$LOCAL\" \"$REMOTE\"";
      };

      mergetool."Kaleidoscope" = {
        cmd = "ksdiff --merge --output \"$MERGED\" --base \"$BASE\" -- \"$LOCAL\" --snapshot \"$REMOTE\" --snapshot";
        trustExitCode = true;
      };

      filter.lfs = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };

      pager = {
        diff = "diff-so-fancy | less --tabs=1,5 -RFX";
        show = "diff-so-fancy | less --tabs=1,5 -RFX";
      };
    };

    # Global gitignore patterns
    ignores = [
      # Extra file for per-machine config
      "*.extra"

      # Compiled source
      "*.com"
      "*.class"
      "*.dll"
      "*.exe"
      "*.o"
      "*.so"

      # Packages
      "*.7z"
      "*.dmg"
      "*.iso"
      "*.rar"
      "*.zip"

      # Logs and databases
      "*.log"
      "*.sqlite"

      # OS generated files
      ".DS_Store"
      ".DS_Store?"
      "._*"
      ".Spotlight-V100"
      ".Trashes"
      "Desktop.ini"
      "ehthumbs.db"
      "Thumbs.db"
      ".idea"
      ".vagrant"

      # Shell Env vars
      ".env"
      "*.envrc"
      "*.env"
      ".direnv"

      # NodeJS
      "node_modules/"

      # Python
      ".python-version"
      "__pycache__/"

      # Tags
      "TAGS"
      ".TAGS"
      "!TAGS/"
      "tags"
      ".tags"
      "!tags/"
      "gtags.files"
      "GTAGS"
      "GRTAGS"
      "GPATH"
      "GSYMS"
      "cscope.files"
      "cscope.out"
      "cscope.in.out"
      "cscope.po.out"

      # Emacs
      ".dir-locals.el"

      # Aider
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
      
      # Clean up
      cleanup = "!git branch --merged | grep -v '\\*\\|master\\|main\\|develop' | xargs -n 1 git branch -d";
      
      # Stash operations
      save = "stash save";
      pop = "stash pop";
      
      # Verbose output
      tags = "tag -l";
      branches = "branch -a";
      remotes = "remote -v";
    };
  };

  # Install required packages for Git integration
  home.packages = with pkgs; [
    git-lfs
    delta
    diff-so-fancy
    gh # GitHub CLI
  ];
}
