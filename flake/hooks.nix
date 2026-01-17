# PARAGON pre-commit hooks via git-hooks.nix
# AST-grep scans rules/paragon/ directory for all YAML rules
{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      pre-commit.settings.hooks = {
        # ═══════════════════════════════════════════════════════════════════════
        # NIX FORMATTING
        # ═══════════════════════════════════════════════════════════════════════
        nixfmt.enable = true;

        # ═══════════════════════════════════════════════════════════════════════
        # PARAGON GUARDS (AST-grep)
        # ═══════════════════════════════════════════════════════════════════════
        # Scans all YAML rules in config/quality/rules/paragon/
        # Matches logic in config/quality/src/hooks/pre-tool-use.ts (SSOT)
        paragon-ast = {
          enable = true;
          name = "paragon-ast";
          description = "PARAGON AST guards: type safety, patterns, stack compliance";
          entry = toString (
            pkgs.writeShellScript "paragon-ast" ''
              # Skip if no files provided
              [ $# -eq 0 ] && exit 0

              # Filter to TypeScript files, excluding guard/tool files
              files=()
              for file in "$@"; do
                case "$file" in
                  *-guard.ts|*/sig-*.ts|*/ast-engine.ts|*.d.ts|*.test.ts|*.spec.ts)
                    continue
                    ;;
                esac
                files+=("$file")
              done

              [ ''${#files[@]} -eq 0 ] && exit 0

              # Scan rules directory
              RULES_DIR="$HOME/dotfiles/config/quality/rules/paragon"
              if [ ! -d "$RULES_DIR" ]; then
                echo "Warning: PARAGON rules directory not found at $RULES_DIR"
                exit 0
              fi

              # Run ast-grep on each rule file
              has_error=0
              for rule in "$RULES_DIR"/*.yml; do
                [ -f "$rule" ] || continue
                output=$(${pkgs.ast-grep}/bin/sg scan --rule "$rule" "''${files[@]}" 2>&1)
                if [ -n "$output" ] && echo "$output" | ${pkgs.ripgrep}/bin/rg -q "Guard"; then
                  echo "$output"
                  has_error=1
                fi
              done

              exit $has_error
            ''
          );
          files = "\\.(ts|tsx)$";
          language = "system";
        };

        # ═══════════════════════════════════════════════════════════════════════════
        # QUALITY VALIDATION (TypeScript typecheck, format, lint, test)
        # ═══════════════════════════════════════════════════════════════════════════
        quality-validate = {
          enable = true;
          name = "quality-validate";
          description = "Run TypeScript validation (typecheck, format, lint, test)";
          entry = toString (
            pkgs.writeShellScript "quality-validate" ''
              cd "$HOME/dotfiles/config/quality"
              ${pkgs.bun}/bin/bun run validate
            ''
          );
          files = "^config/quality/.*\\.(ts|tsx)$";
          pass_filenames = false;
          language = "system";
        };

        # ═══════════════════════════════════════════════════════════════════════════
        # CONVENTIONAL COMMITS
        # ═══════════════════════════════════════════════════════════════════════════
        commitizen.enable = true;
      };
    };
}
