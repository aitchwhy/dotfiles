{ config, lib, pkgs, ... }:

{
  programs.starship = {
    enable = true;
    
    # Enable shell integration
    enableZshIntegration = true;

    # Starship configuration
    settings = {
      # Main prompt format
      format = lib.concatStrings [
        "$username"
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_state"
        "$git_status"
        "$cmd_duration"
        "$line_break"
        "$python"
        "$character"
      ];

      # Directory configuration
      directory = {
        style = "blue";
      };

      # Character configuration
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
        vimcmd_symbol = "[❮](green)";
      };

      # Git branch configuration
      git_branch = {
        format = "[$branch]($style)";
        style = "bright-black";
      };

      # Git status configuration
      git_status = {
        format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style)";
        style = "cyan";
        conflicted = "​";
        untracked = "​";
        modified = "​";
        staged = "​";
        renamed = "​";
        deleted = "​";
        stashed = "≡";
      };

      # Git state configuration
      git_state = {
        format = "\\([$state( $progress_current/$progress_total)]($style)\\) ";
        style = "bright-black";
      };

      # Command duration configuration
      cmd_duration = {
        format = "[$duration]($style) ";
        style = "yellow";
      };

      # Python configuration
      python = {
        format = "[$virtualenv]($style) ";
        style = "bright-black";
      };
    };
  };
}
