# Development shells using git-hooks.nix for pre-commit hooks
{...}: {
  perSystem = {
    config,
    pkgs,
    system,
    ...
  }: {
    # Pre-commit hooks configuration via git-hooks.nix
    # Note: deadnix and statix disabled in CI due to existing code warnings
    # Run manually: deadnix -e . && statix check .
    pre-commit.settings.hooks = {
      # Nix formatting with nixfmt-rfc-style (December 2025 standard)
      nixfmt-rfc-style.enable = true;
    };

    # Development shell with pre-commit hooks integrated
    devShells.default = pkgs.mkShell {
      # Include pre-commit hook installation
      shellHook = ''
        ${config.pre-commit.installationScript}
        echo ""
        echo "Nix Dev Shell (${system})"
        echo ""
        echo "Commands:"
        echo "  just switch  - Rebuild and switch configuration"
        echo "  just update  - Update flake inputs"
        echo "  just fmt     - Format Nix files"
        echo "  just lint    - Run pre-commit hooks"
        echo ""
        echo "Pre-commit hooks: nixfmt-rfc-style"
        echo "Manual linting: deadnix -e . && statix check ."
        echo ""
      '';

      # Packages available in the shell
      packages = with pkgs; [
        nixd
        nixfmt-rfc-style
        deadnix
        statix
        just
        git
        fd
        nix-tree
        nix-diff
        nix-output-monitor
      ];
    };
  };
}
