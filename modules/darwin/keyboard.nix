# macOS keyboard configuration
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
in
{
  options.modules.darwin.keyboard = {
    enable = mkEnableOption "macOS keyboard customization";

    remapCapsLock = mkOption {
      type = types.enum [
        "none"
        "escape"
        "control"
      ];
      # Set to "none" - Kanata handles CapsLock with tap-hold:
      #   Tap = Escape, Hold = Hyper (Ctrl+Alt+Cmd)
      # See: modules/home/apps/kanata.nix
      default = "none";
      description = "Remap Caps Lock key (set to 'none' when using Kanata)";
    };
  };

  config = mkIf config.modules.darwin.keyboard.enable {
    system.keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = config.modules.darwin.keyboard.remapCapsLock == "escape";
      remapCapsLockToControl = config.modules.darwin.keyboard.remapCapsLock == "control";
    };

    # Function keys act as media keys by default (brightness, volume, etc.)
    # F12 = Volume Up, F11 = Volume Down, F10 = Mute, etc.
    # Press Fn + F1-F12 for actual function keys
    system.defaults.NSGlobalDomain."com.apple.keyboard.fnState" = false;
  };
}
