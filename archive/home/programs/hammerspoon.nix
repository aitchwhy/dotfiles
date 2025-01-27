{ config, lib, pkgs, ... }:

{
  home.file = {
    ".hammerspoon" = {
      source = ../../modules/hammerspoon;
      recursive = true;
    };
  };

  # Install Hammerspoon via homebrew in darwin/homebrew.nix
  # This is just for configuration management

  # Additional Hammerspoon-related packages
  home.packages = with pkgs; [
    # Add any additional packages needed by your Hammerspoon configuration
    lua
    luajitPackages.lua-cjson
  ];

  # Environment variables
  home.sessionVariables = {
    # Add any Hammerspoon-specific environment variables here
    HS_CONFIG_DIR = "${config.home.homeDirectory}/.hammerspoon";
  };
}
