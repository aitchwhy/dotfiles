---
name: nix-flake-parts
description: Modular Nix flake composition with flake-parts + git-hooks. December 2025 standard for all projects.
allowed-tools: Read, Write, Edit, Bash, Grep
---

## When to Use

- All new Nix projects (via Signet generators)
- Migrating existing flakes to modular architecture
- Adding development shells with pre-commit hooks
- Multi-system flakes (darwin + linux)

## Architecture

```
flake.nix                    # Entry point using flake-parts.lib.mkFlake
flake/
  darwin.nix                # darwinConfigurations (if needed)
  nixos.nix                 # nixosConfigurations (if needed)
  devshells.nix             # Development shells + pre-commit hooks
  checks.nix                # Custom validation checks
```

## Module Structure

### flake.nix (Entry Point)

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.git-hooks-nix.flakeModule
        ./flake/devshells.nix
      ];

      systems = [ "aarch64-darwin" "x86_64-linux" ];

      perSystem = { pkgs, ... }: {
        formatter = pkgs.nixfmt-rfc-style;
      };
    };
}
```

### flake/devshells.nix (Development Shell with Pre-commit)

```nix
{ inputs, ... }:
{
  perSystem = { config, pkgs, system, ... }: {
    # Pre-commit hooks configuration
    pre-commit.settings.hooks = {
      nixfmt-rfc-style.enable = true;
      deadnix.enable = true;
      statix.enable = true;
    };

    # Development shell with hooks integrated
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

### flake/darwin.nix (Darwin Configurations)

Use `withSystem` to access `self` in system-specific contexts:

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

## Key Concepts

### `perSystem`

Replaces `forAllSystems` helper. Automatically provides `pkgs`, `system`, `config`:

```nix
perSystem = { pkgs, system, config, ... }: {
  # Access to per-system packages
  packages.default = pkgs.hello;

  # Access to pre-commit hooks config
  devShells.default = pkgs.mkShell {
    shellHook = config.pre-commit.installationScript;
  };
};
```

### `withSystem`

Access per-system context from flake-level outputs (like darwinConfigurations):

```nix
{ withSystem, ... }:
{
  flake.darwinConfigurations.foo = withSystem "aarch64-darwin" (
    ctx@{ pkgs, ... }:
    # pkgs is now available here
    ...
  );
}
```

### `self` Reference

In flake-parts, `self` is available at the top level. Pass it via `specialArgs`:

```nix
{ self, inputs, ... }:
{
  flake.darwinConfigurations.foo = inputs.nix-darwin.lib.darwinSystem {
    specialArgs = { inherit inputs self; };  # self works here
    modules = [ ... ];
  };
}
```

## Anti-Patterns

| Anti-Pattern | Correct Pattern |
|--------------|-----------------|
| `forAllSystems` helper | Use flake-parts `systems` + `perSystem` |
| `nixpkgs.legacyPackages.\${system}` | Use `perSystem.pkgs` |
| Manual multi-system devShells | Use `perSystem.devShells.default` |
| Inline pre-commit scripts | Use `git-hooks-nix.flakeModule` |
| `mkShell` without hooks | Include `config.pre-commit.installationScript` |

## Pre-commit Hooks

Available hooks via git-hooks.nix:

```nix
pre-commit.settings.hooks = {
  # Nix
  nixfmt-rfc-style.enable = true;  # RFC 166 formatting
  deadnix.enable = true;            # Remove unused code
  statix.enable = true;             # Static analysis

  # TypeScript (if applicable)
  biome.enable = true;

  # Python (if applicable)
  ruff.enable = true;
};
```

## Commands

```bash
nix develop           # Enter dev shell (installs pre-commit hooks)
nix flake check       # Validate flake + run pre-commit check
nix fmt               # Format with nixfmt-rfc-style
```

## Migration from Traditional Flake

1. Add `flake-parts` and `git-hooks-nix` inputs
2. Replace `outputs = { ... }:` with `flake-parts.lib.mkFlake`
3. Move system-specific code to `perSystem`
4. Move darwin/nixos configs to separate files in `flake/`
5. Remove `forAllSystems` helper

## Reference: Signet SSOT

Version numbers from `config/signet/src/stack/versions.ts`:

```typescript
nix: {
  nixpkgs: 'nixos-unstable',
  'flake-parts': 'github:hercules-ci/flake-parts',
  'git-hooks-nix': 'github:cachix/git-hooks.nix',
  'nixfmt-rfc-style': '0.6.0',
  deadnix: '1.2.1',
  statix: '0.5.8',
  nixd: '2.6.1',
}
```
