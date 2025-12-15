# PARAGON pre-commit hooks via git-hooks.nix
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
        # PARAGON GUARDS (Custom hooks)
        # ═══════════════════════════════════════════════════════════════════════

        # Guard 5: No any types
        paragon-no-any = {
          enable = true;
          name = "paragon-no-any";
          description = "PARAGON Guard 5: Block any type in TypeScript";
          entry = toString (
            pkgs.writeShellScript "check-no-any" ''
              for file in "$@"; do
                # Skip guard/tool files that document these patterns
                if [[ "$file" == *-guard.ts ]] || [[ "$file" == */sig-*.ts ]]; then
                  continue
                fi
                if [[ "$file" == *.ts ]] || [[ "$file" == *.tsx ]]; then
                  if [[ "$file" != *.d.ts ]] && ${pkgs.ripgrep}/bin/rg -q ':\s*any\b|as\s+any\b|<any\s*>' "$file" 2>/dev/null; then
                    echo "PARAGON Guard 5: 'any' type detected in $file"
                    exit 1
                  fi
                fi
              done
            ''
          );
          files = "\\.(ts|tsx)$";
          language = "system";
        };

        # Guard 6: No z.infer
        paragon-no-zinfer = {
          enable = true;
          name = "paragon-no-zinfer";
          description = "PARAGON Guard 6: Block z.infer in TypeScript";
          entry = toString (
            pkgs.writeShellScript "check-no-zinfer" ''
              for file in "$@"; do
                # Skip guard/tool files that document these patterns
                if [[ "$file" == *-guard.ts ]] || [[ "$file" == */sig-*.ts ]] || [[ "$file" == */ast-engine.ts ]]; then
                  continue
                fi
                if [[ "$file" == *.ts ]] || [[ "$file" == *.tsx ]]; then
                  if ${pkgs.ripgrep}/bin/rg -q 'z\.infer\s*<|z\.input\s*<|z\.output\s*<' "$file" 2>/dev/null; then
                    echo "PARAGON Guard 6: z.infer detected in $file"
                    exit 1
                  fi
                fi
              done
            ''
          );
          files = "\\.(ts|tsx)$";
          language = "system";
        };

        # Guard 7: No mocks
        paragon-no-mock = {
          enable = true;
          name = "paragon-no-mock";
          description = "PARAGON Guard 7: Block mock patterns";
          entry = toString (
            pkgs.writeShellScript "check-no-mock" ''
              for file in "$@"; do
                # Skip guard/tool files that document these patterns
                if [[ "$file" == *-guard.ts ]] || [[ "$file" == */sig-*.ts ]]; then
                  continue
                fi
                if [[ "$file" == *.ts ]] || [[ "$file" == *.tsx ]] || [[ "$file" == *.js ]]; then
                  if ${pkgs.ripgrep}/bin/rg -q 'jest\.mock\s*\(|vi\.mock\s*\(|Mock[A-Z][a-zA-Z]*Live' "$file" 2>/dev/null; then
                    echo "PARAGON Guard 7: Mock pattern detected in $file"
                    exit 1
                  fi
                fi
              done
            ''
          );
          files = "\\.(ts|tsx|js)$";
          language = "system";
        };

        # Guard 13: No assumption language
        paragon-no-assumptions = {
          enable = true;
          name = "paragon-no-assumptions";
          description = "PARAGON Guard 13: Block assumption language";
          entry = toString (
            pkgs.writeShellScript "check-no-assumptions" ''
              for file in "$@"; do
                # Skip guard/tool files that document these patterns
                if [[ "$file" == *-guard.ts ]] || [[ "$file" == */sig-*.ts ]]; then
                  continue
                fi
                if [[ "$file" == *.ts ]] || [[ "$file" == *.tsx ]]; then
                  if ${pkgs.ripgrep}/bin/rg -qi 'should (now )?work|should fix|this fixes|probably (works|fixed)|I think (this|it)|might (work|fix)|likely (fixed|works)' "$file" 2>/dev/null; then
                    echo "PARAGON Guard 13: Assumption language detected in $file"
                    exit 1
                  fi
                fi
              done
            ''
          );
          files = "\\.(ts|tsx)$";
          language = "system";
        };

        # Guard 26: No console.* methods (use Effect logging)
        paragon-no-console = {
          enable = true;
          name = "paragon-no-console";
          description = "PARAGON Guard 26: Block console.* methods in TypeScript";
          entry = toString (
            pkgs.writeShellScript "check-no-console" ''
              for file in "$@"; do
                # Skip test files and guard/tool files
                if [[ "$file" == *.test.ts ]] || [[ "$file" == *.spec.ts ]]; then
                  continue
                fi
                if [[ "$file" == *-guard.ts ]] || [[ "$file" == */sig-*.ts ]]; then
                  continue
                fi
                if [[ "$file" == *.ts ]] || [[ "$file" == *.tsx ]]; then
                  if ${pkgs.ripgrep}/bin/rg -q 'console\.(log|error|warn|debug|info)\s*\(' "$file" 2>/dev/null; then
                    echo "PARAGON Guard 26: console.* detected in $file - use Effect logging"
                    exit 1
                  fi
                fi
              done
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
