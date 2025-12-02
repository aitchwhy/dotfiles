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

      # Productivity
      cat = "bat";
      find = "fd";
      grep = "rg";
      ls = "eza";
      tree = "eza --tree";

      # Quick edits
      e = "$EDITOR";
      se = "sudo $EDITOR";

      # Nix
      rebuild = "darwin-rebuild switch --flake ~/.config/nix-darwin";
      update = "nix flake update";
      clean = "nix-collect-garbage -d";
      search = "nix search nixpkgs";
    } // optionalAttrs config.modules.home.shell.aliases.enableGitAliases {
      # Git
      g = "git";
      gs = "git status";
      gp = "git push";
      gl = "git pull";
      gd = "git diff";
      gc = "git commit";
      gco = "git checkout";
      gaa = "git add --all";
    } // optionalAttrs config.modules.home.shell.aliases.enableDockerAliases {
      # Docker
      d = "docker";
      dc = "docker compose";
      dps = "docker ps";
    };
  };
}
