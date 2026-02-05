# Login items via launchd user agents
# Only for apps that do NOT self-register as macOS Login Items.
# Apps like Claude, CleanShot X, Bartender, Raycast, etc. register their
# own Login Items, so adding launchd agents for them causes duplicate launches.
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

    # Apps that don't self-register as Login Items
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
