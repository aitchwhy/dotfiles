---
name: nix-darwin-patterns
description: Nix Flakes + nix-darwin + Home Manager patterns for macOS. Reproducible, declarative system configuration.
allowed-tools: Read, Write, Edit, Bash
---

# Nix Darwin Patterns (December 2025)

## Flake Structure

```
~/dotfiles/
├── flake.nix           # Main entry point
├── flake.lock          # Locked dependencies
├── modules/
│   ├── darwin/         # nix-darwin system modules
│   │   ├── default.nix
│   │   ├── homebrew.nix
│   │   └── system.nix
│   └── home/           # Home Manager modules
│       ├── default.nix
│       ├── shell/
│       │   ├── zsh.nix
│       │   └── aliases.nix
│       └── apps/
│           ├── git.nix
│           ├── neovim.nix
│           └── claude-code.nix
├── config/             # App configs (symlinked)
│   ├── claude-code/
│   ├── nvim/
│   └── starship/
└── hosts/              # Host-specific configs
    └── hank-mbp-m4.nix
```

## Flake Template

```nix
# flake.nix
{
  description = "Dotfiles managed with Nix Flakes";

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
    darwinConfigurations = {
      "hank-mbp-m4" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/hank-mbp-m4.nix
          ./modules/darwin
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.hank = import ./modules/home;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };
    };

    # Formatter
    formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;
  };
}
```

## Home Manager Module Pattern

```nix
# modules/home/apps/example.nix
{ config, lib, pkgs, ... }:

with lib;

{
  options.modules.home.apps.example = {
    enable = mkEnableOption "Example app configuration";
  };

  config = mkIf config.modules.home.apps.example.enable {
    # Install packages
    home.packages = with pkgs; [
      example-package
    ];

    # Symlink config files
    home.file = {
      ".config/example/config.toml".source = ../../../config/example/config.toml;
    };

    # Or write inline config
    home.file.".config/example/settings.json".text = builtins.toJSON {
      setting1 = "value1";
      setting2 = true;
    };

    # Activation scripts for mutable configs
    home.activation.exampleSetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Run after symlinks are created
      $DRY_RUN_CMD mkdir -p ~/.config/example
    '';
  };
}
```

## Darwin System Module Pattern

```nix
# modules/darwin/system.nix
{ config, lib, pkgs, ... }:

{
  # macOS system preferences
  system.defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };

    dock = {
      autohide = true;
      orientation = "left";
      show-recents = false;
    };

    finder = {
      AppleShowAllFiles = true;
      FXPreferredViewStyle = "Nlsv";
      ShowPathbar = true;
    };
  };

  # System packages (available to all users)
  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  # Enable Nix flakes
  nix.settings.experimental-features = ["nix-command" "flakes"];
}
```

## Homebrew Module

```nix
# modules/darwin/homebrew.nix
{ config, lib, pkgs, ... }:

{
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };

    taps = [
      "homebrew/bundle"
    ];

    brews = [
      # CLI tools not in nixpkgs
    ];

    casks = [
      "1password"
      "arc"
      "raycast"
      "cursor"
      "ghostty"
    ];

    masApps = {
      "Bear" = 1091189122;
      "Drafts" = 1435957248;
    };
  };
}
```

## Shell Aliases Module

```nix
# modules/home/shell/aliases.nix
{ config, lib, pkgs, ... }:

{
  programs.zsh.shellAliases = {
    # Nix
    nrs = "darwin-rebuild switch --flake ~/dotfiles#hank-mbp-m4";
    nrb = "darwin-rebuild build --flake ~/dotfiles#hank-mbp-m4";
    nfu = "nix flake update --flake ~/dotfiles";
    ngc = "nix-collect-garbage -d";

    # Claude Code
    cc = "claude";
    cco = "claude --model claude-opus-4-5-20251101";
    ccs = "claude --model claude-sonnet-4-5-20250929";

    # Modern CLI
    ls = "${pkgs.eza}/bin/eza --icons --group-directories-first";
    ll = "${pkgs.eza}/bin/eza -la --icons --group-directories-first";
    lt = "${pkgs.eza}/bin/eza --tree --level=2 --icons";
    cat = "${pkgs.bat}/bin/bat --paging=never";
    grep = "${pkgs.ripgrep}/bin/rg";
    find = "${pkgs.fd}/bin/fd";
  };
}
```

## Common Commands

```bash
# Build without switching (test first)
darwin-rebuild build --flake .#hank-mbp-m4

# Switch to new configuration
darwin-rebuild switch --flake .#hank-mbp-m4

# With sudo for system changes
sudo darwin-rebuild switch --flake .#hank-mbp-m4

# Garbage collection
nix-collect-garbage -d

# Update flake inputs
nix flake update

# Check flake
nix flake check

# Format all Nix files
nix fmt

# Show what would change
darwin-rebuild build --flake .#hank-mbp-m4 && nvd diff /run/current-system result
```

## Debugging Tips

```bash
# Check if a file is symlinked correctly
ls -la ~/.claude/CLAUDE.md

# Verify Home Manager activation
home-manager generations

# Check nix-darwin generation
darwin-rebuild --list-generations

# Trace evaluation errors
nix eval --show-trace .#darwinConfigurations.hank-mbp-m4.system

# Build with verbose output
darwin-rebuild switch --flake .#hank-mbp-m4 --show-trace
```

## Module Registry Pattern

```nix
# modules/home/default.nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./shell/zsh.nix
    ./shell/aliases.nix
    ./apps/git.nix
    ./apps/neovim.nix
    ./apps/claude-code.nix
  ];

  # Enable modules
  modules.home.apps = {
    git.enable = true;
    neovim.enable = true;
    claudeCode.enable = true;
  };

  # Base config
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
}
```
