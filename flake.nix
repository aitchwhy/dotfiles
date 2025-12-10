{
  description = "Hank's Nix Configuration";

  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    warn-dirty = false;
    accept-flake-config = true;
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Flake architecture (December 2025 standard)
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Pre-commit hooks (formerly pre-commit-hooks.nix)
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Darwin & Home Manager
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Homebrew integration (no nixpkgs input to follow)
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # NixOS remote deployment
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Deployment automation
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.git-hooks-nix.flakeModule
        ./flake/darwin.nix
        ./flake/nixos.nix
        ./flake/devshells.nix
        ./flake/checks.nix
        ./flake/deploy.nix
        ./flake/vm-tests.nix
      ];

      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      # Per-system configuration
      perSystem = {pkgs, ...}: {
        # Formatter (nixfmt-rfc-style is December 2025 standard)
        formatter = pkgs.nixfmt-rfc-style;
      };
    };
}
