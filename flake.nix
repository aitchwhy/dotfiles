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

    # Yazi plugins (de-vendored, December 2025)
    # Official yazi-rs plugins (single repo with all plugins)
    yazi-plugins = {
      url = "github:yazi-rs/plugins/63f9650";
      flake = false;
    };

    # Third-party plugins
    yazi-relative-motions = {
      url = "github:dedukun/relative-motions.yazi/ce2e890";
      flake = false;
    };
    yazi-bunny = {
      url = "github:stelcodes/bunny.yazi/059fe22";
      flake = false;
    };
    yazi-projects = {
      url = "github:MasouShizuka/projects.yazi/7037dd5";
      flake = false;
    };
    yazi-ouch = {
      url = "github:ndtoan96/ouch.yazi/10b4627";
      flake = false;
    };
    yazi-lazygit = {
      url = "github:Lil-Dank/lazygit.yazi/7a08a09";
      flake = false;
    };
    yazi-what-size = {
      url = "github:pirafrank/what-size.yazi/0a4904c";
      flake = false;
    };
    yazi-copy-file-contents = {
      url = "github:AnirudhG07/plugins-yazi/907e292";
      flake = false;
    };
    yazi-open-with-cmd = {
      url = "github:Ape/open-with-cmd.yazi/433cf30";
      flake = false;
    };
    yazi-starship = {
      url = "github:Rolv-Apneseth/starship.yazi/6a0f3f7";
      flake = false;
    };
    yazi-glow = {
      url = "github:Reledia/glow.yazi/2da96e3";
      flake = false;
    };
    yazi-rich-preview = {
      url = "github:AnirudhG07/rich-preview.yazi/843c3fa";
      flake = false;
    };

    # Yazi flavors (themes)
    yazi-flavor-ashen = {
      url = "github:ficcdaf/ashen/514ed5a";
      flake = false;
    };
    yazi-flavor-tokyo-night = {
      url = "github:BennyOe/tokyo-night.yazi/b3950bf";
      flake = false;
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
