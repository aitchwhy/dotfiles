# Xcode configuration
{ config, lib, ... }:

with lib;

{
  options.modules.darwin.xcode = {
    enable = mkEnableOption "Xcode customization";

    indentWidth = mkOption {
      type = types.int;
      default = 2;
      description = "Indentation width in spaces";
    };
  };

  config = mkIf config.modules.darwin.xcode.enable {
    system.defaults.CustomUserPreferences."com.apple.dt.Xcode" = {
      DVTTextShowLineNumbers = true;
      DVTTextShowPageGuide = true;
      DVTTextPageGuideLocation = 120;
      DVTTextShowFoldingSidebar = true;
      DVTTextIndentUsingSpaces = true;
      DVTTextIndentWidth = config.modules.darwin.xcode.indentWidth;
      DVTTextTabWidth = config.modules.darwin.xcode.indentWidth;
    };
  };
}
