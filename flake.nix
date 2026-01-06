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

    # Flavors (themes)
    yazi-flavor-ashen = {
      url = "github:ficcdaf/ashen/514ed5a";
      flake = false;
    };
    yazi-flavor-tokyo-night = {
      url = "github:BennyOe/tokyo-night.yazi/b3950bf";
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
