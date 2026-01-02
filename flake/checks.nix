# Custom checks - AI CLI configuration validation with coverage reporting
# All tests are blocking - failures prevent builds
{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        # ═══════════════════════════════════════════════════════════════════════════
        # Quality System TypeScript Validation
        # Validates the Quality System TypeScript code compiles correctly
        # ═══════════════════════════════════════════════════════════════════════════
        quality-typecheck =
          pkgs.runCommand "quality-typecheck"
            {
              nativeBuildInputs = [ pkgs.bun ];
              src = ../.;
            }
            ''
              # Copy source to writable directory
              cp -r $src/config/quality $TMPDIR/brain
              chmod -R u+w $TMPDIR/brain
              cd $TMPDIR/brain

              # Bun needs writable directories
              export HOME="$TMPDIR/home"
              mkdir -p "$HOME"

              echo "═══════════════════════════════════════════════════════════════"
              echo "Quality System TypeCheck"
              echo "═══════════════════════════════════════════════════════════════"

              # Install dependencies (frozen lockfile ensures reproducibility)
              ${pkgs.bun}/bin/bun install --frozen-lockfile

              # Run typecheck
              ${pkgs.bun}/bin/bun x tsc --noEmit

              echo ""
              echo "✓ Quality System TypeScript validation passed"
              touch $out
            '';

        # ═══════════════════════════════════════════════════════════════════════════
        # Port Conflict Detection
        # Validates lib/config/ports.nix has no duplicate port assignments
        # ═══════════════════════════════════════════════════════════════════════════
        port-conflicts =
          let
            cfg = import ../lib/config { inherit (pkgs) lib; };
            failed = builtins.filter (a: !a.assertion) cfg.assertions;
          in
          if failed == [ ] then
            pkgs.runCommand "port-conflicts-check" { } ''
              echo "═══════════════════════════════════════════════════════════════"
              echo "Port Conflict Check - PASSED"
              echo "═══════════════════════════════════════════════════════════════"
              echo ""
              echo "Total ports defined: ${toString (builtins.length cfg.flatPorts)}"
              echo "No duplicate port assignments detected."
              echo ""
              echo "✓ All port assignments are unique"
              touch $out
            ''
          else
            throw (builtins.concatStringsSep "\n" (map (a: a.message) failed));

        # ═══════════════════════════════════════════════════════════════════════════
        # Comprehensive AI CLI Configuration Validation
        # All assertions are BLOCKING - failures exit non-zero
        # ═══════════════════════════════════════════════════════════════════════════

        # ═══════════════════════════════════════════════════════════════════════════
        # Neovim Configuration Validation
        # Validates Lua syntax of all Neovim configuration files
        # ═══════════════════════════════════════════════════════════════════════════
        neovim-config =
          pkgs.runCommand "neovim-config-check"
            {
              nativeBuildInputs = [
                pkgs.luajit
                pkgs.fd
              ];
              src = ../.;
            }
            ''
              cd $src

              echo "═══════════════════════════════════════════════════════════════"
              echo "Neovim Configuration Validation"
              echo "═══════════════════════════════════════════════════════════════"

              ERRORS=0
              TOTAL=0

              echo ""
              echo "─── Lua Syntax Validation ───"

              # Check all Lua files in config/nvim/lua/
              for file in $(${pkgs.fd}/bin/fd -e lua . config/nvim/lua/); do
                TOTAL=$((TOTAL + 1))
                if ${pkgs.luajit}/bin/luajit -bl "$file" /dev/null; then
                  echo "✓ $file"
                else
                  echo "✗ SYNTAX ERROR: $file"
                  ERRORS=$((ERRORS + 1))
                fi
              done

              echo ""
              echo "─── Test Files Validation ───"

              # Check test files (directory may not exist in all configurations)
              if [ -d "config/nvim/tests" ]; then
                for file in $(${pkgs.fd}/bin/fd -e lua . config/nvim/tests/); do
                  TOTAL=$((TOTAL + 1))
                  if ${pkgs.luajit}/bin/luajit -bl "$file" /dev/null; then
                    echo "✓ $file"
                  else
                    echo "✗ SYNTAX ERROR: $file"
                    ERRORS=$((ERRORS + 1))
                  fi
                done
              fi

              echo ""
              echo "─── Mason Configuration Check ───"

              # Verify Mason only has debug adapters (no linters)
              if grep -qE '"(markdownlint|yamllint|hadolint|sqlfluff)"' config/nvim/lua/plugins/mason.lua; then
                echo "✗ Mason contains linters that should be in Nix"
                ERRORS=$((ERRORS + 1))
              else
                echo "✓ Mason correctly limited to debug adapters"
              fi
              TOTAL=$((TOTAL + 1))

              echo ""
              echo "─── Nix LSP Override Check ───"

              # Verify nvim-lspconfig.lua has nixd enabled and nil_ls disabled
              # (Nix LSP config consolidated into nvim-lspconfig.lua per commit a23a599)
              if [ -f "config/nvim/lua/plugins/nvim-lspconfig.lua" ]; then
                if grep -q "nil_ls = false" config/nvim/lua/plugins/nvim-lspconfig.lua; then
                  echo "✓ nil_ls correctly disabled in nvim-lspconfig.lua"
                else
                  echo "✗ nil_ls not disabled in nvim-lspconfig.lua"
                  ERRORS=$((ERRORS + 1))
                fi
                if grep -q "nixd" config/nvim/lua/plugins/nvim-lspconfig.lua; then
                  echo "✓ nixd configured in nvim-lspconfig.lua"
                else
                  echo "✗ nixd not configured in nvim-lspconfig.lua"
                  ERRORS=$((ERRORS + 1))
                fi
              else
                echo "✗ nvim-lspconfig.lua not found"
                ERRORS=$((ERRORS + 1))
              fi
              TOTAL=$((TOTAL + 2))

              echo ""
              echo "═══════════════════════════════════════════════════════════════"
              echo "Summary: $((TOTAL - ERRORS)) / $TOTAL checks passed"
              echo "═══════════════════════════════════════════════════════════════"

              if [ "$ERRORS" -gt 0 ]; then
                echo "✗ $ERRORS error(s) found"
                exit 1
              fi

              echo "✓ All Neovim configuration checks passed"
              touch $out
            '';
      };
    };
}
