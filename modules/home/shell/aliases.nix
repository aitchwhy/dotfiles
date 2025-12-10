# Shell aliases configuration
{
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    optionalAttrs
    ;
in {
  options.modules.home.shell.aliases = {
    enable = mkEnableOption "shell aliases";

    enableGitAliases = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Git aliases";
    };

    enableDockerAliases = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Docker aliases";
    };
  };

  config = mkIf config.modules.home.shell.aliases.enable {
    home.shellAliases =
      {
        # Navigation
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        ll = "ls -l";
        la = "ls -la";
        lt = "ls -la --tree";

        # Modern CLI replacements (use bat/fd/rg explicitly when needed)
        # NOTE: cat alias removed - breaks heredoc in tooling (Claude Code commits)
        find = "fd";
        grep = "rg";
        ls = "eza --git --icons";
        l = "eza --git --icons -lF";
        lll = "eza -1F --git --icons";
        lx = "eza -lbhHigUmuSa@ --color-scale --git --icons";
        llt = "eza -lahF --tree --level=2";
        tree = "eza --tree";

        # Quick edits
        e = "$EDITOR";
        se = "sudo $EDITOR";
        v = "$EDITOR";
        vi = "$EDITOR";
        vim = "$EDITOR";

        # Shell management
        zr = "exec zsh";
        ze = "$EDITOR $ZDOTDIR/.zshrc";

        # Lazygit (CRITICAL)
        lg = "lazygit";
        lgdot = "lazygit --path $DOTFILES";

        # Zellij
        zj = "zellij";
        zjls = "zellij list-sessions";

        # Homebrew
        b = "brew";
        bup = "brew update && brew upgrade";
        bclean = "brew cleanup --prune=all && rm -rf $(brew --cache) && brew autoremove";
        bi = "brew info";
        bin = "brew install";
        brein = "brew reinstall";
        bs = "brew search";

        # Just task runner
        j = "just";

        # System utilities
        ports = "lsof -i -P -n | grep LISTEN";
        printpath = "echo $PATH | tr \":\" \"\\n\"";
        ip = "ipconfig getifaddr en0";
        publicip = "curl -s https://api.ipify.org";
        flush = "dscacheutil -flushcache && killall -HUP mDNSResponder";

        # Tool shortcuts
        pc = "process-compose";
        sp = "supabase";
        ts = "tailscale";
        hf = "huggingface-cli";
        at = "atuin";

        # Signet CLI (Code Quality & Generation Platform)
        s = "signet";
        sig = "signet";

        # Repomix CLI (rx is the script in ~/.local/bin)
        rxy = "rx copy"; # Pack and copy to clipboard
        rxd = "rx dots"; # Pack dotfiles
        rxe = "rx ember"; # Pack ember-platform
        rxr = "rx remote"; # Pack remote repo

        # Claude Code
        cc = "claude";
        ccd = "claude --dangerously-skip-permissions";
        ccr = "claude --resume";
        ccc = "claude --continue";
        ccplan = "claude --model claude-opus-4-5-20251101";
        ccfast = "claude --model claude-sonnet-4-5-20250929";
        ccnew = "claude --new";
        ccv = "claude --verbose";

        # Nix management
        rebuild = "darwin-rebuild switch --flake ~/dotfiles#hank-mbp-m4";
        update = "nix flake update ~/dotfiles && darwin-rebuild switch --flake ~/dotfiles#hank-mbp-m4";
        clean = "nix-collect-garbage -d";
        search = "nix search nixpkgs";
        nd = "nix develop";
        npkgs = "nix search nixpkgs";
        nst = "nix store";
        nf = "nix flake";
        nfc = "nix flake check -L";
        nb = "nix build";
        ncf = "nix config";
        nr = "nix run";
        nfmt = "nix fmt";
        np = "nix profile";
      }
      // optionalAttrs config.modules.home.shell.aliases.enableGitAliases {
        # Git
        g = "git";
        ga = "git add";
        gaa = "git add --all";
        gai = "git add -i";
        gc = "git commit";
        gca = "git commit --amend --no-edit";
        gcm = "git commit -m";
        gs = "git status";
        gp = "git push";
        gpf = "git push --force-with-lease";
        gl = "git pull";
        gpr = "git pull --rebase";
        gd = "git diff";
        gds = "git diff --staged";
        gco = "git checkout";
        gsw = "git switch";
        gw = "git worktree";
        grb = "git rebase";
        grbi = "git rebase -i";
      }
      // optionalAttrs config.modules.home.shell.aliases.enableDockerAliases {
        # Docker
        d = "docker";
        dc = "docker compose";
        dps = "docker ps";
        dpsa = "docker ps -a";
        dimg = "docker images";
        dx = "docker exec -it";
        ld = "lazydocker";
        k = "k9s";
      };
  };
}
