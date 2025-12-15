# PARAGON pre-commit hooks via git-hooks.nix
# Consolidation: 5 individual guards → 1 ast-grep invocation
# Expected speedup: ~5x (5 sequential → 1 parallel)
{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      pre-commit.settings.hooks = {
        # ═══════════════════════════════════════════════════════════════════════
        # NIX FORMATTING
        # ═══════════════════════════════════════════════════════════════════════
        nixfmt-rfc-style.enable = true;

        # ═══════════════════════════════════════════════════════════════════════
        # PARAGON GUARDS (Combined ast-grep)
        # ═══════════════════════════════════════════════════════════════════════
        # Guards 5, 6, 7, 13, 26 combined into single ast-grep invocation
        # Rules: config/agents/rules/paragon-combined.yaml
        paragon-combined = {
          enable = true;
          name = "paragon-combined";
          description = "PARAGON Guards 5,6,7,13,26: AST-based TypeScript validation";
          entry = toString (
            pkgs.writeShellScript "paragon-combined" ''
              # Skip if no files provided
              [ $# -eq 0 ] && exit 0

              # Filter to only TypeScript files, excluding guards/tools
              files=()
              for file in "$@"; do
                # Skip guard/tool files that document these patterns
                case "$file" in
                  *-guard.ts|*/sig-*.ts|*/ast-engine.ts|*.d.ts|*.test.ts|*.spec.ts)
                    continue
                    ;;
                esac
                files+=("$file")
              done

              # Exit if no files to check after filtering
              [ ''${#files[@]} -eq 0 ] && exit 0

              # Run ast-grep with combined rules
              # Note: ast-grep processes all rules in one pass (parallel)
              RULES_FILE="$HOME/dotfiles/config/agents/rules/paragon-combined.yaml"
              if [ ! -f "$RULES_FILE" ]; then
                echo "Warning: PARAGON rules file not found at $RULES_FILE"
                exit 0
              fi

              output=$(${pkgs.ast-grep}/bin/sg scan --rule "$RULES_FILE" "''${files[@]}" 2>&1)
              exit_code=$?

              if [ $exit_code -ne 0 ] || [ -n "$output" ]; then
                echo "$output"
                # ast-grep returns 0 even with matches, check for actual violations
                if echo "$output" | ${pkgs.ripgrep}/bin/rg -q "PARAGON Guard"; then
                  exit 1
                fi
              fi

              exit 0
            ''
          );
          files = "\\.(ts|tsx)$";
          language = "system";
        };

        # ═══════════════════════════════════════════════════════════════════════
        # CONVENTIONAL COMMITS
        # ═══════════════════════════════════════════════════════════════════════
        commitizen.enable = true;
      };
    };
}
