# Flake Checks - SOTA Testing (January 2026)
#
# Architecture:
# 1. Pure Nix tests via lib.debug.runTests (pattern validation)
# 2. Module assertions via lib/testing (compile-time checks)
# 3. Derivations only where runtime is required (TypeScript, Lua syntax, Zellij CLI)
#
# SSOT: All test logic lives in lib/testing/*.nix
# DRY: Reusable validators, no duplicate patterns
{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      lib = pkgs.lib;
      src = self;

      # Import the type-safe testing library
      testing = import ../lib/testing { inherit lib src; };

      # Run all pure Nix tests
      testResults = testing.runAllTests;

      # Check if any tests failed
      hasFailures = testResults != [ ];

      # Format test failures for error message
      formatFailures =
        failures:
        lib.concatStringsSep "\n" (
          map (
            f: "  FAIL: ${f.name}\n    Expected: ${toString f.expected}\n    Got: ${toString f.result}"
          ) failures
        );

    in
    {
      checks = {
        # ═══════════════════════════════════════════════════════════════════════════
        # PURE NIX TESTS - Pattern Validation (no runtime required)
        # Uses lib.debug.runTests for structured output
        # ═══════════════════════════════════════════════════════════════════════════
        config-patterns =
          if hasFailures then
            throw ''
              Configuration pattern validation failed!

              ${formatFailures testResults}

              Fix the issues above and run `nix flake check` again.
            ''
          else
            pkgs.runCommand "config-patterns-check" { } ''
              echo "═══════════════════════════════════════════════════════════════"
              echo "Configuration Pattern Validation - PASSED"
              echo "═══════════════════════════════════════════════════════════════"
              echo ""
              echo "NeoVim tests: ${toString (builtins.length (builtins.attrNames testing.neovim.tests))}"
              echo "Zellij tests: ${toString (builtins.length (builtins.attrNames testing.zellij.tests))}"
              echo "Quality tests: ${toString (builtins.length (builtins.attrNames testing.quality.tests))}"
              echo ""
              echo "✓ All pattern validations passed"
              touch $out
            '';

        # ═══════════════════════════════════════════════════════════════════════════
        # PORT CONFLICT DETECTION - Pure Nix Assertions
        # Validates lib/config/ports.nix has no duplicate port assignments
        # ═══════════════════════════════════════════════════════════════════════════
        port-conflicts =
          let
            cfg = import ../lib/config { inherit lib; };
            failed = builtins.filter (a: !a.assertion) cfg.assertions;
          in
          if failed == [ ] then
            pkgs.runCommand "port-conflicts-check" { } ''
              echo "═══════════════════════════════════════════════════════════════"
              echo "Port Conflict Check - PASSED"
              echo "═══════════════════════════════════════════════════════════════"
              echo ""
              echo "Total ports defined: ${toString (builtins.length cfg.flatPorts)}"
              echo "✓ All port assignments are unique"
              touch $out
            ''
          else
            throw (builtins.concatStringsSep "\n" (map (a: a.message) failed));

        # ═══════════════════════════════════════════════════════════════════════════
        # QUALITY SYSTEM TYPECHECK - Requires Bun Runtime
        # TypeScript validation cannot be done in pure Nix
        # ═══════════════════════════════════════════════════════════════════════════
        quality-typecheck =
          pkgs.runCommand "quality-typecheck"
            {
              nativeBuildInputs = [ pkgs.bun ];
              src = ./..;
            }
            ''
              cp -r $src/config/quality $TMPDIR/quality
              chmod -R u+w $TMPDIR/quality
              cd $TMPDIR/quality

              export HOME="$TMPDIR/home"
              mkdir -p "$HOME"

              echo "═══════════════════════════════════════════════════════════════"
              echo "Quality System TypeCheck"
              echo "═══════════════════════════════════════════════════════════════"

              ${pkgs.bun}/bin/bun install --frozen-lockfile
              ${pkgs.bun}/bin/bun x tsc --noEmit

              echo ""
              echo "✓ Quality System TypeScript validation passed"
              touch $out
            '';

        # ═══════════════════════════════════════════════════════════════════════════
        # ZELLIJ CONFIG - Requires Zellij CLI for KDL Validation
        # Official `zellij setup --check` validates KDL syntax
        # Anti-pattern checks are done in pure Nix (testing.zellij)
        # ═══════════════════════════════════════════════════════════════════════════
        zellij-syntax =
          pkgs.runCommand "zellij-syntax-check"
            {
              nativeBuildInputs = [ pkgs.zellij ];
              src = ./..;
            }
            ''
              export ZELLIJ_CONFIG_DIR="$src/config/zellij"

              echo "═══════════════════════════════════════════════════════════════"
              echo "Zellij KDL Syntax Validation"
              echo "═══════════════════════════════════════════════════════════════"

              if ${pkgs.zellij}/bin/zellij setup --check 2>&1 | grep -q "Well defined"; then
                echo "✓ config.kdl KDL syntax is valid"
              else
                echo "✗ Zellij config KDL syntax validation failed:"
                ${pkgs.zellij}/bin/zellij setup --check 2>&1
                exit 1
              fi

              touch $out
            '';

        # ═══════════════════════════════════════════════════════════════════════════
        # NEOVIM LUA SYNTAX - Requires LuaJIT for Bytecode Compilation
        # Validates Lua files compile without syntax errors
        # Pattern validation is done in pure Nix (testing.neovim)
        # ═══════════════════════════════════════════════════════════════════════════
        neovim-lua-syntax =
          pkgs.runCommand "neovim-lua-syntax-check"
            {
              nativeBuildInputs = [
                pkgs.luajit
                pkgs.fd
              ];
              src = ./..;
            }
            ''
              cd $src

              echo "═══════════════════════════════════════════════════════════════"
              echo "NeoVim Lua Syntax Validation"
              echo "═══════════════════════════════════════════════════════════════"

              ERRORS=0
              TOTAL=0

              # Validate all Lua files compile to bytecode
              for file in $(${pkgs.fd}/bin/fd -e lua . config/nvim/lua/ config/nvim/tests/ 2>/dev/null); do
                TOTAL=$((TOTAL + 1))
                if ${pkgs.luajit}/bin/luajit -bl "$file" /dev/null 2>/dev/null; then
                  echo "✓ $file"
                else
                  echo "✗ SYNTAX ERROR: $file"
                  ERRORS=$((ERRORS + 1))
                fi
              done

              echo ""
              echo "───────────────────────────────────────────────────────────────"
              echo "Validated $TOTAL Lua files"

              if [ "$ERRORS" -gt 0 ]; then
                echo "✗ $ERRORS syntax error(s) found"
                exit 1
              fi

              echo "✓ All Lua files have valid syntax"
              touch $out
            '';
      };
    };
}
