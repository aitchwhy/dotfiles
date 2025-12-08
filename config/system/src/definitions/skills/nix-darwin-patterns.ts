/**
 * Nix Darwin Patterns Skill Definition
 *
 * Nix Flakes + nix-darwin + Home Manager patterns for macOS.
 * Migrated from: config/claude-code/skills/nix-darwin-patterns/SKILL.md
 */
import type { SystemSkill } from '@/schema'

export const nixDarwinPatternsSkill: SystemSkill = {
  name: 'nix-darwin-patterns' as SystemSkill['name'],
  description:
    'Nix Flakes + nix-darwin + Home Manager patterns for macOS. Reproducible, declarative system configuration.',
  allowedTools: ['Read', 'Write', 'Edit', 'Bash'] as SystemSkill['allowedTools'],

  sections: [
    {
      title: 'Flake Structure',
      patterns: [
        {
          title: 'Directory Layout',
          annotation: 'info',
          language: 'text',
          code: `~/dotfiles/
├── flake.nix           # Main entry point
├── flake.lock          # Locked dependencies
├── modules/
│   ├── darwin/         # nix-darwin system modules
│   └── home/           # Home Manager modules
├── config/             # App configs (symlinked)
└── hosts/              # Host-specific configs`,
        },
      ],
    },
    {
      title: 'Flake Template',
      patterns: [
        {
          title: 'Basic flake.nix',
          annotation: 'do',
          language: 'nix',
          code: `{
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
}`,
        },
      ],
    },
    {
      title: 'Home Manager Module Pattern',
      patterns: [
        {
          title: 'Module with Options',
          annotation: 'do',
          language: 'nix',
          code: `{ config, lib, pkgs, ... }:
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
}`,
        },
      ],
    },
    {
      title: 'Darwin System Module',
      patterns: [
        {
          title: 'macOS Preferences',
          annotation: 'do',
          language: 'nix',
          code: `{ config, lib, pkgs, ... }:
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
}`,
        },
      ],
    },
    {
      title: 'Common Commands',
      patterns: [
        {
          title: 'Darwin Rebuild',
          annotation: 'info',
          language: 'bash',
          code: `darwin-rebuild build --flake .#hostname   # Build only
darwin-rebuild switch --flake .#hostname  # Apply changes
nix flake update                          # Update inputs
nix-collect-garbage -d                    # Cleanup
nix flake check                           # Validate`,
        },
      ],
    },
  ],
}
