# Login items via launchd user agents
# These apps start automatically on login
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.modules.darwin.loginItems;
in
{
  options.modules.darwin.loginItems = {
    enable = mkEnableOption "macOS login items via launchd";

    # System utilities
    swish = mkOption {
      type = types.bool;
      default = true;
      description = "Start Swish (trackpad gestures) at login";
    };

    homerow = mkOption {
      type = types.bool;
      default = true;
      description = "Start Homerow (keyboard navigation) at login";
    };

    # Core productivity apps
    bartender = mkOption {
      type = types.bool;
      default = true;
      description = "Start Bartender (menu bar manager) at login";
    };

    betterDisplay = mkOption {
      type = types.bool;
      default = true;
      description = "Start BetterDisplay (display manager) at login";
    };

    raycast = mkOption {
      type = types.bool;
      default = true;
      description = "Start Raycast (launcher) at login";
    };

    cleanShot = mkOption {
      type = types.bool;
      default = true;
      description = "Start CleanShot X (screenshot tool) at login";
    };

    # Security & sync
    bitwarden = mkOption {
      type = types.bool;
      default = true;
      description = "Start Bitwarden (password manager) at login";
    };

    googleDrive = mkOption {
      type = types.bool;
      default = true;
      description = "Start Google Drive at login";
    };

    # Developer tools
    orbStack = mkOption {
      type = types.bool;
      default = true;
      description = "Start OrbStack (container runtime) at login";
    };

    # Communication & productivity
    claude = mkOption {
      type = types.bool;
      default = true;
      description = "Start Claude (AI assistant) at login";
    };

    superhuman = mkOption {
      type = types.bool;
      default = true;
      description = "Start Superhuman (email) at login";
    };

    todoist = mkOption {
      type = types.bool;
      default = true;
      description = "Start Todoist (task manager) at login";
    };

    fantastical = mkOption {
      type = types.bool;
      default = true;
      description = "Start Fantastical (calendar) at login";
    };

    rcmd = mkOption {
      type = types.bool;
      default = true;
      description = "Start rcmd (Right Command shortcuts) at login";
    };
  };

  config = mkIf cfg.enable {
    launchd.user.agents = {
      # System utilities
      swish = mkIf cfg.swish {
        serviceConfig = {
          Label = "co.highlyopinionated.swish";
          ProgramArguments = [ "/Applications/Swish.app/Contents/MacOS/Swish" ];
          RunAtLoad = true;
          KeepAlive = false;
        };
      };

      homerow = mkIf cfg.homerow {
        serviceConfig = {
          Label = "com.superultra.Homerow";
          ProgramArguments = [ "/Applications/Homerow.app/Contents/MacOS/Homerow" ];
          RunAtLoad = true;
          KeepAlive = false;
        };
      };

      # Core productivity apps
      bartender = mkIf cfg.bartender {
        serviceConfig = {
          Label = "com.surteesstudios.Bartender";
          ProgramArguments = [ "/Applications/Bartender 6.app/Contents/MacOS/Bartender 6" ];
          RunAtLoad = true;
          KeepAlive = false;
        };
      };

      betterDisplay = mkIf cfg.betterDisplay {
        serviceConfig = {
          Label = "pro.betterdisplay.BetterDisplay";
          ProgramArguments = [ "/Applications/BetterDisplay.app/Contents/MacOS/BetterDisplay" ];
          RunAtLoad = true;
          KeepAlive = false;
        };
      };

      raycast = mkIf cfg.raycast {
        serviceConfig = {
          Label = "com.raycast.macos";
          ProgramArguments = [ "/Applications/Raycast.app/Contents/MacOS/Raycast" ];
          RunAtLoad = true;
          KeepAlive = false;
        };
      };

      cleanShot = mkIf cfg.cleanShot {
        serviceConfig = {
          Label = "pl.maketheweb.cleanshotx";
          ProgramArguments = [ "/Applications/CleanShot X.app/Contents/MacOS/CleanShot X" ];
          RunAtLoad = true;
          KeepAlive = false;
        };
      };

      # Security & sync
      bitwarden = mkIf cfg.bitwarden {
        serviceConfig = {
          Label = "com.bitwarden.desktop";
          ProgramArguments = [ "/Applications/Bitwarden.app/Contents/MacOS/Bitwarden" ];
          RunAtLoad = true;
          KeepAlive = false;
        };
      };

      googleDrive = mkIf cfg.googleDrive {
        serviceConfig = {
          Label = "com.google.drivefs";
          ProgramArguments = [ "/Applications/Google Drive.app/Contents/MacOS/Google Drive" ];
          RunAtLoad = true;
          KeepAlive = false;
        };
      };

      # Developer tools
      orbStack = mkIf cfg.orbStack {
        serviceConfig = {
          Label = "com.orbstack.OrbStack";
          ProgramArguments = [ "/Applications/OrbStack.app/Contents/MacOS/OrbStack" ];
          RunAtLoad = true;
          KeepAlive = false;
        };
      };

      # Communication & productivity
      claude = mkIf cfg.claude {
        serviceConfig = {
          Label = "com.anthropic.claudefordesktop";
          ProgramArguments = [ "/Applications/Claude.app/Contents/MacOS/Claude" ];
          RunAtLoad = true;
          KeepAlive = false;
        };
      };

      superhuman = mkIf cfg.superhuman {
        serviceConfig = {
          Label = "com.superhuman.mail";
          ProgramArguments = [ "/Applications/Superhuman.app/Contents/MacOS/Superhuman" ];
          RunAtLoad = true;
          KeepAlive = false;
        };
      };

      todoist = mkIf cfg.todoist {
        serviceConfig = {
          Label = "com.todoist.mac.Todoist";
          ProgramArguments = [ "/Applications/Todoist.app/Contents/MacOS/Todoist" ];
          RunAtLoad = true;
          KeepAlive = false;
        };
      };

      fantastical = mkIf cfg.fantastical {
        serviceConfig = {
          Label = "com.flexibits.fantastical2.mac";
          ProgramArguments = [ "/Applications/Fantastical.app/Contents/MacOS/Fantastical" ];
          RunAtLoad = true;
          KeepAlive = false;
        };
      };

      rcmd = mkIf cfg.rcmd {
        serviceConfig = {
          Label = "com.lowtechguys.rcmd";
          ProgramArguments = [ "/Applications/rcmd.app/Contents/MacOS/rcmd" ];
          RunAtLoad = true;
          KeepAlive = false;
        };
      };
    };
  };
}
