---
name: nix-darwin-patterns
description: Nix Flakes + nix-darwin + Home Manager patterns for macOS. Reproducible, declarative system configuration.
allowed-tools: Read, Write, Edit, Bash
---

## Flake Structure

### Directory Layout

```
~/dotfiles/
├── flake.nix           # Main entry point
├── flake.lock          # Locked dependencies
├── modules/
│   ├── darwin/         # nix-darwin system modules
│   └── home/           # Home Manager modules
├── config/             # App configs (symlinked)
└── hosts/              # Host-specific configs
```

## Flake Template

### Basic flake.nix

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }@inputs: {
    darwinConfigurations."hostname" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ./modules/darwin
        home-manager.darwinModules.home-manager
        { home-manager.users.username = import ./modules/home; }
      ];
    };
  };
}
```

## Home Manager Module Pattern

### Module with Options

```nix
{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.home.apps.example;
in
{
  options.modules.home.apps.example = {
    enable = mkEnableOption "Example app configuration";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ example-package ];
    home.file.".config/example/config.toml".source = ./config.toml;
  };
}
```

## Darwin System Module

### macOS Preferences

```nix
{ config, lib, pkgs, ... }:
{
  system.defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };
    dock = { autohide = true; orientation = "left"; };
    finder = { AppleShowAllFiles = true; ShowPathbar = true; };
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];
}
```

## Common Commands

### Darwin Rebuild

```bash
darwin-rebuild build --flake .#hostname   # Build only
darwin-rebuild switch --flake .#hostname  # Apply changes
nix flake update                          # Update inputs
nix-collect-garbage -d                    # Cleanup
nix flake check                           # Validate
```
