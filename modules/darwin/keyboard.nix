# macOS keyboard configuration
{ config, lib, ... }:

with lib;

{
  options.modules.darwin.keyboard = {
    enable = mkEnableOption "macOS keyboard customization";

    remapCapsLock = mkOption {
      type = types.enum [ "none" "escape" "control" ];
      default = "none";  # Kanata handles CapsLock -> Escape/Hyper
      description = "Remap Caps Lock key";
    };
  };

  config = mkIf config.modules.darwin.keyboard.enable {
    system.keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = config.modules.darwin.keyboard.remapCapsLock == "escape";
      remapCapsLockToControl = config.modules.darwin.keyboard.remapCapsLock == "control";
    };
  };
}
