# Zellij terminal multiplexer configuration
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  zellijConfig = ../../../config/zellij;

  # Plugin sources from flake inputs
  # zjstatus: Built WASM from flake
  zjstatusWasm = "${
    inputs.zjstatus.packages.${pkgs.stdenv.hostPlatform.system}.default
  }/bin/zjstatus.wasm";

  # room: Fetch pre-built WASM from GitHub releases
  roomWasm = pkgs.fetchurl {
    url = "https://github.com/rvcas/room/releases/download/v1.2.0/room.wasm";
    sha256 = "sha256-t6GPP7OOztf6XtBgzhLF+edUU294twnu0y5uufXwrkw=";
  };

  configFiles = {
    "zellij/config.kdl".source = "${zellijConfig}/config.kdl";
    "zellij/layouts/default.kdl".source = "${zellijConfig}/layouts/default.kdl";
  };

  pluginFiles = {
    "zellij/plugins/zjstatus.wasm".source = zjstatusWasm;
    "zellij/plugins/room.wasm".source = roomWasm;
  };
in
{
  options.modules.home.tools.zellij = {
    enable = mkEnableOption "zellij terminal multiplexer";
  };

  config = mkIf config.modules.home.tools.zellij.enable {
    programs.zellij = {
      enable = true;
      enableZshIntegration = false; # Manual control preferred
      enableBashIntegration = false;
    };

    # Link config files and plugins individually (like yazi pattern)
    xdg.configFile = configFiles // pluginFiles;
  };
}
