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

## Modern Architecture (December 2025)

### flake-parts Integration

For dotfiles and darwin configurations, use flake-parts:

```nix
{ self, inputs, withSystem, ... }:
{
  flake.darwinConfigurations.hostname = withSystem "aarch64-darwin" (
    ctx@{ pkgs, ... }:
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs self; };
      modules = [
        ../modules/darwin
        inputs.home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs self; };
            users.username = import ../users/username.nix;
          };
        }
      ];
    }
  );
}
```

### Key Points

- Use `withSystem` to access `self` in system-specific contexts
- Pass `self` via `specialArgs` for home-manager modules
- Use `perSystem.devShells.default` instead of manual `forAllSystems`
- See `nix-flake-parts` skill for full flake-parts patterns

## Bleeding Edge Philosophy (December 2025)

### Version Strategy

- **Always use unstable**: `nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"`
- **Track master for home-manager**: For stateVersion 26.05+
- **Prefer current over LTS**: Node.js current (25.x) not LTS (22.x)

### stateVersion Policy

Use the latest available stateVersion even if marked unstable:
```nix
home.stateVersion = "26.05";  # Bleeding edge
system.stateVersion = "26.05";  # NixOS
```

### Node.js: Current Not LTS

```nix
# ✓ Use nodejs (tracks latest current)
home.packages = [ pkgs.nodejs ];

# ✗ Avoid pinned LTS versions
home.packages = [ pkgs.nodejs_22 ];
```

### Python Policy: 3.14+ Only

```nix
# ✓ Approved - Python 3.14+
home.packages = [ pkgs.python314 ];

# ✗ BANNED - Python < 3.14
home.packages = [ pkgs.python312 ];  # Not allowed
home.packages = [ pkgs.python313 ];  # Not allowed
```

### Database Policy (December 2025)

**Approved databases:**
- PostgreSQL 18+ (`postgresql_18` in Nix)
- SQLite/Turso 3.50+ (`libsql-client` for Turso)

**BANNED:**
- MySQL (all versions) - use PostgreSQL instead

```nix
# ✓ Approved databases
home.packages = [ pkgs.postgresql_18 ];

# ✗ BANNED - will fail enforcement
home.packages = [ pkgs.mysql84 ];       # MySQL not allowed
home.packages = [ pkgs.postgresql_17 ]; # PostgreSQL < 18 not allowed
home.packages = [ pkgs.postgresql_16 ]; # PostgreSQL < 18 not allowed
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
