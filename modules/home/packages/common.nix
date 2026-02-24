# Cross-platform packages (shared between macOS and Linux)
# Most CLI tools moved to Homebrew brews (managed via nix-darwin)
# Only Nix-specific tools and custom packages remain here
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf optionals;
  cfg = config.modules.home.packages;
in
{
  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      # Kubernetes & Infrastructure
      (optionals cfg.enableKubernetes [
        pulumi-esc # ESC CLI for secrets/config management (not in Homebrew)
      ])
      # Databases (not in Homebrew)
      ++ (optionals cfg.enableDatabases [
        drizzle-kit # Drizzle ORM CLI + Studio GUI (npm package)
        usql # Universal SQL client (Go binary)
      ])
      # Nix Code Quality & Formatting
      ++ [
        nixfmt
        deadnix
        statix
        treefmt
      ]
      # Nix Development Tools
      ++ (optionals cfg.enableNixTools [
        cachix
        devenv
        nixd
        nix-tree
        tree-sitter # Required for LazyVim 15.x treesitter parser compilation
        nix-output-monitor
        nix-diff
      ])
      # Standalone binaries (no Python deps, not in Homebrew)
      ++ [
        bun # For MCP servers, scripts, and fast execution
        ralph-claude-code # Autonomous AI development loop
        agent-browser # AI browser automation CLI (run `agent-browser install` on first use)
      ];

    # Declarative uv setup - installs Python and tools after uv is available
    home.activation.setupUvTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      UV="/etc/profiles/per-user/${config.home.username}/bin/uv"

      if [ -x "$UV" ]; then
        echo "Setting up Python environment via uv..."

        # Install Python 3.14 and set as default
        "$UV" python install 3.14 --default 2>/dev/null || true

        # Install Python tools (ruff for linting/formatting)
        "$UV" tool install ruff@latest 2>/dev/null || true

        echo "uv setup complete: Python 3.14 + ruff"
      fi
    '';
  };
}
