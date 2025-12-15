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

    amphetamine = mkOption {
      type = types.bool;
      default = true;
      description = "Start Amphetamine (keep awake) at login";
    };
  };

  config = mkIf cfg.enable {
    launchd.user.agents = {
      # Swish - trackpad window management gestures
      swish = mkIf cfg.swish {
        serviceConfig = {
          Label = "co.highlyopinionated.swish";
          ProgramArguments = [ "/Applications/Swish.app/Contents/MacOS/Swish" ];
          RunAtLoad = true;
          KeepAlive = false;
        };
      };

      # Homerow - keyboard navigation for UI elements
      homerow = mkIf cfg.homerow {
        serviceConfig = {
          Label = "com.superultra.Homerow";
          ProgramArguments = [ "/Applications/Homerow.app/Contents/MacOS/Homerow" ];
          RunAtLoad = true;
          KeepAlive = false;
        };
      };

      # Amphetamine - prevent system sleep
      amphetamine = mkIf cfg.amphetamine {
        serviceConfig = {
          Label = "com.if.Amphetamine";
          ProgramArguments = [ "/Applications/Amphetamine.app/Contents/MacOS/Amphetamine" ];
          RunAtLoad = true;
          KeepAlive = false;
        };
      };
    };
  };
}
