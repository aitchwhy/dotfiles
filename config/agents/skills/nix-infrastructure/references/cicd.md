# CI/CD Patterns

## GitHub Actions with Cachix

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: DeterminateSystems/nix-installer-action@main

      - uses: DeterminateSystems/magic-nix-cache-action@main

      - uses: cachix/cachix-action@v15
        with:
          name: my-cache
          authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'

      - name: Check
        run: nix flake check

      - name: Build
        run: nix build .#default

      - name: Build Container
        if: github.ref == 'refs/heads/main'
        run: nix build .#container-api
```

## Colmena Deployment

```nix
# flake/deploy.nix
{ self, inputs, ... }:
{
  flake.colmena = {
    meta = {
      nixpkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
      specialArgs = { inherit inputs self; };
    };

    defaults = {
      deployment = {
        buildOnTarget = false;  # Build locally or via nixbuild.net
        replaceUnknownProfiles = true;
      };
    };

    cloud-nixos = {
      deployment = {
        targetHost = "cloud-nixos.tail12345.ts.net";  # Tailscale MagicDNS
        targetUser = "root";
      };
      imports = [ self.nixosModules.cloud ];
    };
  };
}
```

## Deploy Commands

```bash
# Deploy single host
nix run nixpkgs#colmena -- apply --on cloud-nixos

# Deploy all hosts
nix run nixpkgs#colmena -- apply

# Parallel deployment with streaming evaluator
nix run nixpkgs#colmena -- apply --evaluator streaming
```

## Flake Input Setup

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Local orchestration
    process-compose-flake = {
      url = "github:Platonic-Systems/process-compose-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Container builds
    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Deployment
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```
