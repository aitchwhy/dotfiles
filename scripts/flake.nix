{
  description = "Google Docs to Markdown converter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        python = pkgs.python311;
        pythonPackages = python.pkgs;
        
        pythonEnv = python.withPackages (ps: with ps; [
          google-api-python-client
          google-auth
          google-auth-oauthlib
          google-auth-httplib2
        ]);
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            pythonEnv
            uv
            
            # Development tools
            ruff
            black
            mypy
            
            # Utilities
            direnv
            git
          ];

          shellHook = ''
            echo "🐍 Python ${python.version} development environment"
            echo "📦 Run 'uv sync' to install project dependencies"
            echo "🚀 Run 'uv run python google-docs.py' to download documents"
            echo ""
            echo "Available tools:"
            echo "  - uv: Modern Python package manager"
            echo "  - ruff: Fast Python linter"
            echo "  - black: Python code formatter"
            echo "  - mypy: Static type checker"
            
            # Create .venv symlink for better IDE support
            if [ ! -e .venv ] && [ -d ./.venv-* ]; then
              ln -sf .venv-* .venv
            fi
          '';
        };

        packages.default = pkgs.writeShellScriptBin "google-docs-downloader" ''
          #!${pkgs.stdenv.shell}
          export PATH="${pythonEnv}/bin:${pkgs.uv}/bin:$PATH"
          exec uv run python ${./google-docs.py} "$@"
        '';
      });
}