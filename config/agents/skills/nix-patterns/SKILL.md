---
name: nix-patterns
description: Nix Flakes + flake-parts + nix-darwin + Home Manager patterns. Modular composition for macOS configuration.
allowed-tools: Read, Write, Edit, Bash, Grep
token-budget: 700
---

## Architecture

```
~/dotfiles/
├── flake.nix           # Entry point using flake-parts.lib.mkFlake
├── flake.lock          # Locked dependencies
├── flake/
│   ├── darwin.nix      # darwinConfigurations
│   ├── devshells.nix   # Development shells + pre-commit hooks
│   └── checks.nix      # Custom validation checks
├── modules/
│   ├── darwin/         # nix-darwin system modules
│   └── home/           # Home Manager modules
└── lib/
    └── ports.nix       # Centralized port allocation
```

## Flake Template (flake-parts)

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.git-hooks-nix.flakeModule
        ./flake/darwin.nix
        ./flake/devshells.nix
      ];

      systems = [ "aarch64-darwin" "x86_64-linux" ];

      perSystem = { pkgs, ... }: {
        formatter = pkgs.nixfmt-rfc-style;
      };
    };
}
```

## Darwin Configuration (flake/darwin.nix)

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

## Development Shell (flake/devshells.nix)

```nix
{ inputs, ... }:
{
  perSystem = { config, pkgs, system, ... }: {
    pre-commit.settings.hooks = {
      nixfmt-rfc-style.enable = true;
      deadnix.enable = true;
      statix.enable = true;
    };

    devShells.default = pkgs.mkShell {
      shellHook = ''
        ${config.pre-commit.installationScript}
        echo "Dev Shell (${system})"
      '';

      packages = with pkgs; [
        nixd
        nixfmt-rfc-style
        just
        git
      ];
    };
  };
}
```

## Home Manager Module Pattern

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

## macOS System Preferences

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

## Key Concepts

### `perSystem`

Replaces `forAllSystems` helper:

```nix
perSystem = { pkgs, system, config, ... }: {
  packages.default = pkgs.hello;
  devShells.default = pkgs.mkShell {
    shellHook = config.pre-commit.installationScript;
  };
};
```

### `withSystem`

Access per-system context from flake-level outputs:

```nix
{ withSystem, ... }:
{
  flake.darwinConfigurations.foo = withSystem "aarch64-darwin" (
    ctx@{ pkgs, ... }: ...
  );
}
```

### `self` Reference

Pass `self` via `specialArgs`:

```nix
{ self, inputs, ... }:
{
  flake.darwinConfigurations.foo = inputs.nix-darwin.lib.darwinSystem {
    specialArgs = { inherit inputs self; };
    modules = [ ... ];
  };
}
```

## Version Policy (December 2025)

- **nixpkgs**: `nixos-unstable`
- **stateVersion**: `26.05` (bleeding edge)
- **Node.js**: Current (25.x) not LTS
- **Python**: 3.14+ only
- **PostgreSQL**: 18+ only

## Anti-Patterns

| Anti-Pattern | Correct Pattern |
|--------------|-----------------|
| `forAllSystems` helper | Use flake-parts `systems` + `perSystem` |
| `nixpkgs.legacyPackages.\${system}` | Use `perSystem.pkgs` |
| `with lib;` | Use `inherit (lib) ...` |
| Manual multi-system devShells | Use `perSystem.devShells.default` |
| Inline pre-commit scripts | Use `git-hooks-nix.flakeModule` |

## Commands

```bash
darwin-rebuild switch --flake .#hostname  # Apply changes
nix develop           # Enter dev shell
nix flake check       # Validate flake
nix fmt               # Format with nixfmt-rfc-style
nix flake update      # Update inputs
```

## See Also

- `nix-build-optimization` - Derivation splitting, Cachix
- `nix-infrastructure` - Port registry, nix2container
- `secrets-management` - sops-nix patterns
