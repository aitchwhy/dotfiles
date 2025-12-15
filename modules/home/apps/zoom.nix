# Zoom video conferencing configuration
# Note: Meeting defaults (Personal Room, passcodes, mute) are account-level
# settings at zoom.us - not configurable via local plist
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
  cfg = config.modules.home.apps.zoom;
in
{
  options.modules.home.apps.zoom = {
    enable = mkEnableOption "Zoom client settings";

    spellChecking = mkOption {
      type = types.bool;
      default = true;
      description = "Enable continuous spell checking in chat";
    };

    grammarChecking = mkOption {
      type = types.bool;
      default = true;
      description = "Enable grammar checking in chat";
    };

    showNotificationCenter = mkOption {
      type = types.bool;
      default = true;
      description = "Show Zoom in notification center";
    };
  };

  config = mkIf cfg.enable {
    targets.darwin.defaults."us.zoom.xos" = {
      # Text input settings
      ZMInputTextViewContinuousSpellCheckingEnabled = cfg.spellChecking;
      ZMInputTextViewGrammarCheckingEnabled = cfg.grammarChecking;
      ZMInputTextViewAutomaticSpellingCorrectionEnabled = cfg.spellChecking;

      # Notifications
      kZMShowNotificationCenter = cfg.showNotificationCenter;

      # Web/text settings
      WebContinuousSpellCheckingEnabled = cfg.spellChecking;
      NSAllowContinuousSpellChecking = cfg.spellChecking;
    };
  };
}
