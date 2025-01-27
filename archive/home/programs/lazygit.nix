{ config, lib, pkgs, ... }:

{
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        # Show file tree
        showFileTree = true;
        # Show command log
        showCommandLog = true;
        # Show bottom line
        showBottomLine = true;
        # Show random tip
        showRandomTip = true;
        # Show list of keybindings
        showKeybindings = true;
        # Show commit hash
        showCommitHash = true;
        # Border theme
        border = "rounded";
        # Mouse support
        mouseEvents = true;
        # Skip unstaging confirmation
        skipUnstageLineWarning = true;
        # Skip no verify commit warning
        skipNoVerifyWarning = true;
        # Theme variant (dark/light)
        theme = {
          lightTheme = false;
          activeBorderColor = [ "green" "bold" ];
          inactiveBorderColor = [ "white" ];
          selectedLineBgColor = [ "blue" ];
          selectedRangeBgColor = [ "blue" ];
        };
      };

      git = {
        # Automatically fetch
        autoFetch = true;
        # Automatically refresh
        autoRefresh = true;
        # Branch sort order
        branchSortOrder = "recency";
        # Pull mode (merge/rebase/ff-only)
        pullMode = "ff-only";
        # Skip hook prefix
        skipHookPrefix = "WIP";
        # Parse emoji
        parseEmoji = true;
        # Log command template
        logCommandTemplate = "git log --graph --color=always --abbrev-commit --decorate --date=relative --pretty=medium --oneline {{.FilterArgs}} {{.RefFilterArgs}}";
      };

      # Custom commands
      customCommands = [
        {
          key = "W";
          command = "git commit -m 'WIP: {{index .PromptResponses 0}}'";
          context = "files";
          description = "Commit a WIP change";
          prompts = [
            {
              type = "input";
              title = "Commit message";
              initialValue = "";
            }
          ];
        }
        {
          key = "<c-r>";
          command = "git rebase -i {{index .PromptResponses 0}}";
          context = "commits";
          description = "Interactive rebase";
          prompts = [
            {
              type = "input";
              title = "Rebase onto";
              initialValue = "HEAD~";
            }
          ];
        }
      ];

      # Keybinding overrides
      keybinding = {
        universal = {
          quit = "q";
          return = "<esc>";
          quitWithoutChanging = "Q";
          togglePanel = "<tab>";
          prevItem = "<up>";
          nextItem = "<down>";
          prevPage = "<pgup>";
          nextPage = "<pgdown>";
          gotoTop = "g";
          gotoBottom = "G";
          prevBlock = "<left>";
          nextBlock = "<right>";
          nextMatch = "n";
          prevMatch = "N";
          startSearch = "/";
          optionMenu = "x";
          edit = "e";
          new = "n";
          scrollUpMain = "<c-u>";
          scrollDownMain = "<c-d>";
          scrollUpMainHalfPage = "<c-u>";
          scrollDownMainHalfPage = "<c-d>";
        };

        files = {
          commitChanges = "c";
          commitChangesWithEditor = "C";
          amendLastCommit = "A";
          commitChangesWithoutHook = "w";
          ignoreFile = "i";
          refreshFiles = "r";
          stashAllChanges = "s";
          viewStashOptions = "S";
          toggleStagedAll = "<c-s>";
          viewResetOptions = "D";
          fetch = "f";
        };

        branches = {
          createPullRequest = "o";
          checkoutBranchByName = "c";
          forceCheckoutBranch = "F";
          rebaseBranch = "r";
          mergeIntoCurrentBranch = "M";
          viewGitFlowOptions = "i";
          fastForward = "f";
          pushTag = "P";
          setUpstream = "u";
          fetchRemote = "f";
        };

        commits = {
          squashDown = "s";
          renameCommit = "r";
          renameCommitWithEditor = "R";
          viewResetOptions = "g";
          markCommitAsFixup = "f";
          createFixupCommit = "F";
          squashAboveCommits = "S";
          moveDownCommit = "<c-j>";
          moveUpCommit = "<c-k>";
          amendToCommit = "A";
          pickCommit = "p";
          revertCommit = "t";
          cherryPickCopy = "c";
          cherryPickCopyRange = "C";
          pasteCommits = "v";
          tagCommit = "T";
          checkoutCommit = "<space>";
          resetCherryPick = "<c-R>";
        };

        stash = {
          popStash = "g";
          renameStash = "r";
        };

        status = {
          checkForUpdate = "u";
          recentRepos = "<enter>";
        };
      };

      # Confirmation settings
      confirmOnQuit = true;
      quitOnTopLevelReturn = true;

      # Update settings
      update = {
        method = "prompt";
        days = 14;
      };

      # Refreshing settings
      refresher = {
        refreshInterval = 10;
        fetchInterval = 60;
      };

      # OS specific settings
      os = {
        editCommand = "nvim";
        editCommandTemplate = "{{editor}} {{filename}}";
        openCommand = "open {{filename}}";
      };
    };
  };

  # Additional packages that might be needed
  home.packages = with pkgs; [
    delta # For better git diffs
    git-flow # For git flow support
  ];

  # Shell aliases
  programs.zsh.shellAliases = {
    lg = "lazygit";
  };
}
