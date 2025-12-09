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

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nix-homebrew,
      disko,
      sops-nix,
      ...
    }@inputs:
    let
      # System definitions
      darwinSystem = "aarch64-darwin";
      linuxSystem = "x86_64-linux";

      # Package sets
      darwinPkgs = nixpkgs.legacyPackages.${darwinSystem};
      linuxPkgs = nixpkgs.legacyPackages.${linuxSystem};

      # Centralized version management (Signet)
      versions = import ./lib/versions.nix;

      # Helper for multi-system support
      forAllSystems = nixpkgs.lib.genAttrs [
        darwinSystem
        linuxSystem
      ];
    in
    {
      darwinConfigurations.hank-mbp-m4 = nix-darwin.lib.darwinSystem {
        system = darwinSystem;
        specialArgs = { inherit inputs self versions; };
        modules = [
          sops-nix.darwinModules.sops
          ./modules/nixpkgs.nix
          ./modules/darwin
          ./modules/homebrew.nix
          ./hosts/hank-mbp-m4.nix

          # User configuration
          {
            system.primaryUser = "hank";
            users.users.hank = {
              uid = 501;
              description = "Hank Lee";
              home = "/Users/hank";
              shell = darwinPkgs.zsh;
            };
            programs.zsh.enable = true;
            environment.shells = [
              darwinPkgs.bashInteractive
              darwinPkgs.zsh
            ];
          }

          # Home Manager
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs self versions; };
              users.hank = import ./users/hank.nix;
              backupFileExtension = "backup";
            };
          }

          # Homebrew
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              user = "hank";
              autoMigrate = true;
            };
          }
        ];
      };

      # NixOS configuration for cloud development
      nixosConfigurations.cloud = nixpkgs.lib.nixosSystem {
        system = linuxSystem;
        specialArgs = { inherit inputs self versions; };
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./hosts/cloud/configuration.nix
          ./modules/nixpkgs.nix
          ./modules/nixos

          # Home Manager for NixOS
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs self versions; };
              users.hank = import ./users/hank-linux.nix;
              backupFileExtension = "backup";
            };
          }
        ];
      };

      # Development shells (multi-system)
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nixd
              nixfmt-rfc-style
              deadnix
              statix
              just
              git
              fd
            ];
            shellHook = ''
              echo "Nix Dev Shell (${system})"
              echo "Commands:"
              echo "  just switch  - Rebuild and switch configuration"
              echo "  just update  - Update flake inputs"
              echo "  just fmt     - Format Nix files"
            '';
          };
        }
      );

      # Formatters (multi-system)
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      # Checks (multi-system)
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          # Validate AI CLI configuration files (single source of truth)
          ai-cli-config = pkgs.runCommand "ai-cli-config-check" {
            nativeBuildInputs = [ pkgs.jq ];
            src = ./.;
          } ''
            cd $src

            # Validate JSON configs
            for json in config/agents/settings/*.json config/agents/mcp-servers.json; do
              echo "✓ $json"
              ${pkgs.jq}/bin/jq . "$json" > /dev/null
            done

            # Validate skills
            for skill in config/agents/skills/*/; do
              test -f "$skill/SKILL.md" || { echo "Missing SKILL.md in $skill"; exit 1; }
              echo "✓ $skill"
            done

            # Validate commands
            for cmd in config/agents/commands/*.md; do
              test -f "$cmd" || { echo "Missing command: $cmd"; exit 1; }
              echo "✓ $cmd"
            done

            # Validate hooks referenced in settings exist
            for hook in unified-guard.ts unified-polish.ts enforce-versions.ts \
                        session-start.sh session-stop.sh verification-gate.ts assumption-detector.ts; do
              test -f "config/agents/hooks/$hook" || { echo "Missing hook: $hook"; exit 1; }
              echo "✓ hooks/$hook"
            done

            # Output coverage summary
            echo ""
            echo "Coverage: $(ls config/agents/skills/ | wc -l | tr -d ' ') skills"
            echo "Coverage: $(ls config/agents/commands/*.md | wc -l | tr -d ' ') commands"
            echo "Coverage: $(ls config/agents/hooks/*.ts config/agents/hooks/*.sh 2>/dev/null | wc -l | tr -d ' ') hooks"

            echo ""
            echo "All AI CLI config checks passed"
            touch $out
          '';
        }
      );
    };
}
