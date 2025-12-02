# Terminal.app configuration
{ config, lib, ... }:

with lib;

{
  options.modules.darwin.terminal = {
    enable = mkEnableOption "Terminal.app customization";
  };

  config = mkIf config.modules.darwin.terminal.enable {
    system.defaults.CustomUserPreferences."com.apple.terminal" = {
      SecureKeyboardEntry = true;
      ShowLineMarks = false;
    };
  };
}
