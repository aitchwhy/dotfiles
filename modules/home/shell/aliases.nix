# Shell aliases configuration
{ config, lib, ... }:

with lib;

{
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
    home.shellAliases = {
      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      ll = "ls -l";
      la = "ls -la";
      lt = "ls -la --tree";

      # Modern CLI replacements
      cat = "bat";
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
      rx = "repomix";
      at = "atuin";
      aero = "aerospace";

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
    } // optionalAttrs config.modules.home.shell.aliases.enableGitAliases {
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
      gll = "git pull";
      gl = "git pull";
      gd = "git diff";
      gco = "git checkout";
      gw = "git worktree";
    } // optionalAttrs config.modules.home.shell.aliases.enableDockerAliases {
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
