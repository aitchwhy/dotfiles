# Neovim editor configuration
{ config, lib, ... }:

with lib;

{
  options.modules.home.editors.neovim = {
    enable = mkEnableOption "Neovim editor";

    makeDefault = mkOption {
      type = types.bool;
      default = true;
      description = "Make Neovim the default editor";
    };
  };

  config = mkIf config.modules.home.editors.neovim.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = config.modules.home.editors.neovim.makeDefault;
      viAlias = true;
      vimAlias = true;
    };

    home.sessionVariables = mkIf config.modules.home.editors.neovim.makeDefault {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };
}
