# Custom keyboard layout without dead keys or special characters
# Option key acts purely as a modifier (no accented characters on Option+key)
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.modules.home.apps.keyboardLayout = {
    enable = mkEnableOption "US keyboard layout without special characters on Option";
  };

  config = mkIf config.modules.home.apps.keyboardLayout.enable {
    # Install keyboard layout bundle to user's Library
    # After installation: System Settings > Keyboard > Input Sources > Add "US No Special"
    home.file."Library/Keyboard Layouts/US-No-Special.bundle" = {
      source = ../../../config/keyboard-layouts/US-No-Special.bundle;
      recursive = true;
    };
  };
}
