# Development shells - PARAGON hooks imported from flake/hooks.nix
{ ... }:
{
  imports = [ ./hooks.nix ];

  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    {
      # Development shell with pre-commit hooks integrated
      devShells.default = pkgs.mkShell {
        # Include pre-commit hook installation
        shellHook = ''
          ${config.pre-commit.installationScript}
          echo ""
          echo "Nix Dev Shell (${system})"
          echo ""
          echo "Commands:"
          echo "  just switch         - Rebuild and switch configuration"
          echo "  just update         - Update flake inputs"
          echo "  just fmt            - Format Nix files"
          echo "  just lint           - Run pre-commit hooks"
          echo "  just verify-paragon - Run PARAGON verification"
          echo ""
          echo "PARAGON pre-commit hooks active:"
          echo "  nixfmt, biome, commitizen"
          echo "  paragon-no-any, paragon-no-zinfer, paragon-no-mock"
          echo "  paragon-no-assumptions"
          echo ""
          echo "Manual linting: deadnix -e . && statix check ."
          echo ""
        '';

        # Packages available in the shell
        packages =
          (with pkgs; [
            nixd
            nixfmt
            deadnix
            statix
            just
            git
            fd
            nix-tree
            nix-diff
            nix-output-monitor
            biome
            pnpm
            nodejs_25
          ])
          # Include pre-commit hook tools in PATH for manual use
          ++ config.pre-commit.settings.enabledPackages;
      };
    };
}
