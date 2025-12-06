# Starship prompt configuration
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf concatStrings;
in
{
  options.modules.home.shell.starship = {
    enable = mkEnableOption "starship prompt";
  };

  config = mkIf config.modules.home.shell.starship.enable {
    programs.starship = {
      enable = true;
      settings = {
        "$schema" = "https://starship.rs/config-schema.json";
        add_newline = false;
        right_format = "$time$battery $os";
        scan_timeout = 10;

        format = concatStrings [
          "[░▒▓](#a3aed2)"
          "[  ](bg:#a3aed2 fg:#090c0c)"
          "[](bg:#769ff0 fg:#a3aed2)"
          "$directory"
          "[](fg:#769ff0 bg:#394260)"
          "$git_branch"
          "$git_state"
          "$git_status"
          "[](fg:#394260 bg:#212736)"
          "$nix_shell"
          "$nodejs"
          "$python"
          "$golang"
          "[](fg:#212736 bg:#1d2230)"
          "$direnv"
          "[ ](fg:#1d2230)"
          "\n$character"
        ];

        directory = {
          style = "fg:#e3e5e5 bg:#769ff0";
          format = "[ $path ]($style)";
          truncation_length = 5;
          truncation_symbol = "…/";
          substitutions = {
            "Documents" = "󰈙 ";
          };
        };

        git_branch = {
          symbol = "";
          style = "bg:#394260";
          truncation_length = 20;
          format = "[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)";
        };

        git_status = {
          style = "bg:#394260";
          format = "[[($all_status$ahead_behind)](fg:#769ff0 bg:#394260)]($style)";
        };

        nodejs = {
          symbol = "";
          style = "bg:#212736";
          format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
        };

        rust = {
          symbol = "";
          style = "bg:#212736";
          format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
        };

        golang = {
          symbol = "";
          style = "bg:#212736";
          format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
        };

        python = {
          symbol = "";
          style = "bg:#212736";
          format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
        };

        pulumi = {
          symbol = "";
          style = "bg:#212736";
          format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
        };

        time = {
          disabled = false;
          time_format = "%R";
          style = "bg:#1d2230";
          format = "[[  $time ](fg:#a0a9cb bg:#1d2230)]($style)";
        };

        os = {
          format = "on [($name )]($style)";
          style = "bold blue";
          disabled = false;
        };

        os.symbols = {
          NixOS = "❄️ ";
          Macos = " ";
        };

        nix_shell = {
          disabled = false;
          impure_msg = "[impure shell](bold red)";
          pure_msg = "[pure shell](bold green)";
          unknown_msg = "[unknown shell](bold yellow)";
          format = "via [☃️ $state( \\($name\\))](bold blue) ";
        };

        shell = {
          fish_indicator = "󰈺 ";
          powershell_indicator = "_";
          zsh_indicator = "zsh ";
          bash_indicator = "bash ";
          unknown_indicator = "mystery shell";
          style = "cyan bold";
          disabled = false;
          format = "[$indicator]($style)";
        };

        battery = {
          full_symbol = "🔋";
          charging_symbol = "⚡️";
          discharging_symbol = "💀";
        };

        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[✗](bold red)";
        };
      };
    };
  };
}
