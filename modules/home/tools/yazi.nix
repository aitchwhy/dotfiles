{
  config,
  lib,
  inputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf nameValuePair;
  yaziConfig = ../../../config/yazi;

  officialPlugins = [
    "smart-enter"
    "diff"
    "full-border"
    "jump-to-char"
    "mactag"
    "mime-ext"
    "mount"
    "piper"
    "smart-filter"
    "toggle-pane"
    "vcs-files"
  ];

  thirdPartyPlugins = {
    relative-motions = inputs.yazi-relative-motions;
    bunny = inputs.yazi-bunny;
    projects = inputs.yazi-projects;
    ouch = inputs.yazi-ouch;
    lazygit = inputs.yazi-lazygit;
    what-size = inputs.yazi-what-size;
    copy-file-contents = "${inputs.yazi-copy-file-contents}/copy-file-contents.yazi";
    open-with-cmd = inputs.yazi-open-with-cmd;
    starship = inputs.yazi-starship;
    glow = inputs.yazi-glow;
    rich-preview = inputs.yazi-rich-preview;
  };

  localPlugins = [
    "folder-rules"
    "smart-paste"
  ];

  flavors = {
    ashen = "${inputs.yazi-flavor-ashen}/ashen.yazi";
    tokyo-night = inputs.yazi-flavor-tokyo-night;
  };

  mkOfficialPlugin =
    name: nameValuePair "yazi/plugins/${name}.yazi" { source = "${inputs.yazi-plugins}/${name}.yazi"; };

  mkThirdPartyPlugin = name: source: nameValuePair "yazi/plugins/${name}.yazi" { source = source; };

  mkLocalPlugin =
    name: nameValuePair "yazi/plugins/${name}.yazi" { source = "${yaziConfig}/plugins/${name}.yazi"; };

  mkFlavor = name: source: nameValuePair "yazi/flavors/${name}.yazi" { source = source; };

  configFiles = {
    "yazi/yazi.toml".source = "${yaziConfig}/yazi.toml";
    "yazi/keymap.toml".source = "${yaziConfig}/keymap.toml";
    "yazi/theme.toml".source = "${yaziConfig}/theme.toml";
    "yazi/init.lua".source = "${yaziConfig}/init.lua";
    "yazi/package.toml".source = "${yaziConfig}/package.toml";
  };

  pluginFiles = builtins.listToAttrs (
    (map mkOfficialPlugin officialPlugins)
    ++ (lib.mapAttrsToList mkThirdPartyPlugin thirdPartyPlugins)
    ++ (map mkLocalPlugin localPlugins)
    ++ (lib.mapAttrsToList mkFlavor flavors)
  );
in
{
  options.modules.home.tools.yazi.enable = mkEnableOption "yazi file manager";

  config = mkIf config.modules.home.tools.yazi.enable {
    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };

    xdg.configFile = configFiles // pluginFiles;
  };
}
