# Shell prompt configuration (Starship)
{ config, lib, ... }:

with lib;

{
  options.modules.home.shell.prompts = {
    enable = mkEnableOption "shell prompt configuration";

    style = mkOption {
      type = types.enum [ "minimal" "full" "custom" ];
      default = "minimal";
      description = "Prompt style preset";
    };
  };

  config = mkIf config.modules.home.shell.prompts.enable {
    programs.starship = {
      enable = true;
      settings =
        if config.modules.home.shell.prompts.style == "minimal" then {
          format = "$username$hostname$directory$git_branch$git_status$cmd_duration$line_break$character";

          add_newline = false;

          directory = {
            truncation_length = 3;
            truncate_to_repo = true;
            style = "bold cyan";
          };

          git_branch = {
            symbol = " ";
            style = "bold purple";
          };

          git_status = {
            disabled = false;
            style = "bold red";
          };

          cmd_duration = {
            min_time = 500;
            format = " [$duration]($style)";
            style = "bold yellow";
          };

          character = {
            success_symbol = "[❯](bold green)";
            error_symbol = "[❯](bold red)";
            vimcmd_symbol = "[❮](bold green)";
          };
        } else if config.modules.home.shell.prompts.style == "full" then {
          # Full configuration with all modules enabled
          format = lib.concatStrings [
            "$username"
            "$hostname"
            "$directory"
            "$git_branch"
            "$git_status"
            "$git_metrics"
            "$fill"
            "$nodejs"
            "$python"
            "$rust"
            "$golang"
            "$cmd_duration"
            "$line_break"
            "$jobs"
            "$battery"
            "$time"
            "$status"
            "$os"
            "$container"
            "$shell"
            "$character"
          ];
        } else {
          # Custom - user should override settings
        };
    };
  };
}
