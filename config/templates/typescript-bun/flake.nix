{
  description = "PROJECT_NAME - TypeScript/Bun project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # Core
            bun
            nodejs_22

            # TypeScript tooling
            typescript
            nodePackages.typescript-language-server

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

          shellHook = ''
            echo "TypeScript/Bun Development Shell"
            echo "  bun dev      - Start development server"
            echo "  bun test     - Run tests"
            echo "  bun validate - Run all checks"
          '';
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
