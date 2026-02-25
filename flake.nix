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
    # ═══════════════════════════════════════════════════════════════════════════
    # CORE INFRASTRUCTURE
    # ═══════════════════════════════════════════════════════════════════════════
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ═══════════════════════════════════════════════════════════════════════════
    # DARWIN & HOME MANAGER
    # ═══════════════════════════════════════════════════════════════════════════
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # Homebrew taps (declarative, tracks latest)
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    # Custom tap for depot CLI
    homebrew-depot = {
      url = "github:depot/homebrew-tap";
      flake = false;
    };

    # ═══════════════════════════════════════════════════════════════════════════
    # SECRETS MANAGEMENT
    # ═══════════════════════════════════════════════════════════════════════════
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ═══════════════════════════════════════════════════════════════════════════
    # YAZI ECOSYSTEM
    # See: modules/home/tools/yazi.nix for usage
    # ═══════════════════════════════════════════════════════════════════════════

    # Official plugins (single repo)
    yazi-plugins = {
      url = "github:yazi-rs/plugins/57f1863";
      flake = false;
    };

    # Third-party plugins
    yazi-relative-motions = {
      url = "github:dedukun/relative-motions.yazi/a603d9e";
      flake = false;
    };
    yazi-bunny = {
      url = "github:stelcodes/bunny.yazi/6ee99bc";
      flake = false;
    };
    yazi-projects = {
      url = "github:MasouShizuka/projects.yazi/eed0657";
      flake = false;
    };
    yazi-ouch = {
      url = "github:ndtoan96/ouch.yazi/594b8a2";
      flake = false;
    };
    yazi-lazygit = {
      url = "github:Lil-Dank/lazygit.yazi/0e56060";
      flake = false;
    };
    yazi-what-size = {
      url = "github:pirafrank/what-size.yazi/179ebf6";
      flake = false;
    };
    yazi-copy-file-contents = {
      url = "github:AnirudhG07/plugins-yazi/71545f4";
      flake = false;
    };
    yazi-open-with-cmd = {
      url = "github:Ape/open-with-cmd.yazi/e3d430f";
      flake = false;
    };
    yazi-starship = {
      url = "github:Rolv-Apneseth/starship.yazi/eca1861";
      flake = false;
    };
    yazi-glow = {
      url = "github:Reledia/glow.yazi/bd3eaa5";
      flake = false;
    };
    yazi-rich-preview = {
      url = "github:AnirudhG07/rich-preview.yazi/573b275";
      flake = false;
    };

    # Flavors (themes)
    yazi-flavor-ashen = {
      url = "github:ficcdaf/ashen/8add1b8";
      flake = false;
    };
    yazi-flavor-tokyo-night = {
      url = "github:BennyOe/tokyo-night.yazi/8e6296f";
      flake = false;
    };

    # ═══════════════════════════════════════════════════════════════════════════
    # ZELLIJ PLUGINS
    # ═══════════════════════════════════════════════════════════════════════════
    zjstatus = {
      url = "github:dj95/zjstatus/v0.22.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zellij-room = {
      url = "github:rvcas/room/v1.2.0";
      flake = false;
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.git-hooks-nix.flakeModule
        ./flake/treefmt.nix
        ./flake/darwin.nix
        ./flake/devshells.nix
        ./flake/checks.nix
      ];

      systems = [
        "aarch64-darwin"
      ];

      # Per-system configuration handled by imported modules:
      # - treefmt.nix: formatter via treefmt-nix
      # - devshells.nix: development shell
      # - checks.nix: flake checks
    };
}
