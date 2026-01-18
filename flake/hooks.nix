# Pre-commit hooks via git-hooks.nix
# Local-first architecture: project hooks via lefthook, Nix for CI validation
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
        # AST-GREP TEMPLATES (for CI validation only)
        # ═══════════════════════════════════════════════════════════════════════
        # Validates that template rules are syntactically correct
        # Project-specific enforcement is done via local lefthook
        paragon-ast = {
          enable = true;
          name = "paragon-ast";
          description = "Validate AST-grep rule templates are syntactically correct";
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

              # Scan templates directory for effect-ts rules
              RULES_DIR="$HOME/dotfiles/config/quality/rules/templates/effect-ts"
              if [ ! -d "$RULES_DIR" ]; then
                # Templates not installed - skip validation
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
        # QUALITY VALIDATION (CI only - local uses lefthook)
        # ═══════════════════════════════════════════════════════════════════════════
        # Disabled for local development - use lefthook instead
        # Nix sandbox doesn't have access to $HOME/dotfiles structure
        # quality-validate = { ... };

        # ═══════════════════════════════════════════════════════════════════════════
        # CONVENTIONAL COMMITS
        # ═══════════════════════════════════════════════════════════════════════════
        commitizen.enable = true;
      };
    };
}
