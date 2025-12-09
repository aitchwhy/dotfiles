{
  description = "PROJECT_NAME - TypeScript/Bun project with devenv";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs =
    {
      self,
      nixpkgs,
      devenv,
      ...
    }@inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [
              (
                {
                  pkgs,
                  config,
                  ...
                }:
                {
                  # Environment name (shown in shell prompt)
                  name = "PROJECT_NAME";

                  # Packages available in the shell
                  packages = with pkgs; [
                    # Core runtime
                    bun
                    nodejs_22

                    # TypeScript tooling
                    typescript
                    nodePackages.typescript-language-server

                    # Code quality
                    biome

                    # Database (uncomment as needed)
                    # turso-cli
                    # sqlite

                    # Deployment (uncomment as needed)
                    # flyctl
                    # wrangler

                    # Testing (uncomment as needed)
                    # playwright

                    # Utilities
                    jq
                    fd
                    ripgrep
                  ];

                  # Environment variables
                  env = {
                    # Bun settings
                    BUN_RUNTIME_TRANSPILER_CACHE_PATH = ".cache/bun";
                  };

                  # Shell hook runs on enter
                  enterShell = ''
                    echo ""
                    echo "  PROJECT_NAME Development Shell"
                    echo "  ────────────────────────────────"
                    echo "  bun dev      - Start development server"
                    echo "  bun test     - Run tests"
                    echo "  bun validate - Run all checks (typecheck + lint + test)"
                    echo ""
                  '';

                  # Pre-commit hooks (optional)
                  # pre-commit.hooks = {
                  #   biome = {
                  #     enable = true;
                  #     entry = "biome check --write";
                  #     pass_filenames = false;
                  #   };
                  # };

                  # Process management (optional)
                  # processes = {
                  #   dev-server.exec = "bun run dev";
                  # };

                  # ══════════════════════════════════════════════════════════════════
                  # 12-Factor: Backing services as attached resources
                  # Uncomment to enable local development services
                  # ══════════════════════════════════════════════════════════════════

                  # services.postgres = {
                  #   enable = true;
                  #   initialDatabases = [{ name = "dev"; }];
                  # };

                  # services.redis = {
                  #   enable = true;
                  # };
                }
              )
            ];
          };
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    };
}
