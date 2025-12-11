# Custom checks - AI CLI configuration validation with coverage reporting
# All tests are blocking - failures prevent builds
{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        # Signet TypeScript type checking
        signet-typecheck =
          pkgs.runCommand "signet-typecheck"
            {
              nativeBuildInputs = [
                pkgs.bun
                pkgs.nodejs
              ];
              src = ../config/signet;
            }
            ''
              # Copy source to writable location
              cp -r $src signet
              chmod -R u+w signet
              cd signet

              ${pkgs.bun}/bin/bun install --frozen-lockfile
              ${pkgs.bun}/bin/bun run typecheck
              touch $out
            '';

        # ═══════════════════════════════════════════════════════════════════════════
        # Comprehensive AI CLI Configuration Validation
        # All assertions are BLOCKING - failures exit non-zero
        # ═══════════════════════════════════════════════════════════════════════════
        ai-cli-config =
          pkgs.runCommand "ai-cli-config-check"
            {
              nativeBuildInputs = [
                pkgs.jq
                pkgs.gnused
                pkgs.gawk
                pkgs.coreutils
              ];
              src = ../.;
            }
            ''
              cd $src
              TESTS_PASSED=0
              TESTS_TOTAL=0

              # Helper functions (POSIX-compatible)
              assert_pass() {
                TESTS_PASSED=$((TESTS_PASSED + 1))
                TESTS_TOTAL=$((TESTS_TOTAL + 1))
                echo "✓ $1"
              }
              assert_fail() {
                TESTS_TOTAL=$((TESTS_TOTAL + 1))
                echo "✗ ERROR: $1"
                exit 1
              }

              echo "═══════════════════════════════════════════════════════════════"
              echo "AI CLI Configuration Tests - BLOCKING MODE"
              echo "═══════════════════════════════════════════════════════════════"

              # ─────────────────────────────────────────────────────────────────────
              # Test 1: Skills Cross-Reference (directory vs agents.nix)
              # ─────────────────────────────────────────────────────────────────────
              echo ""
              echo "─── Test 1: Skills Cross-Reference ───"

              # Get skills defined in directory (portable)
              SKILLS_DIR=$(ls -1 config/agents/skills/ | sort)
              SKILLS_DIR_COUNT=$(echo "$SKILLS_DIR" | wc -l | tr -d ' ')

              # Get skills symlinked in agents.nix (portable sed extraction)
              SKILLS_NIX=$(grep '\.claude/skills/' config/agents/nix/agents.nix | \
                sed -E 's/.*\.claude\/skills\/([a-z0-9-]+)".*/\1/' | sort | uniq)
              SKILLS_NIX_COUNT=$(echo "$SKILLS_NIX" | wc -l | tr -d ' ')

              # Assertion: All skills in directory are symlinked
              MISSING=$(comm -23 <(echo "$SKILLS_DIR") <(echo "$SKILLS_NIX") | head -1)
              if [ -n "$MISSING" ]; then
                assert_fail "Skills in directory but NOT symlinked: $MISSING"
              fi
              assert_pass "All $SKILLS_DIR_COUNT skills in directory are symlinked"

              # Assertion: No orphan symlinks
              ORPHAN=$(comm -13 <(echo "$SKILLS_DIR") <(echo "$SKILLS_NIX") | head -1)
              if [ -n "$ORPHAN" ]; then
                assert_fail "Broken symlink (directory missing): $ORPHAN"
              fi
              assert_pass "No orphan symlinks in agents.nix"

              # Assertion: Counts match exactly
              if [ "$SKILLS_DIR_COUNT" -ne "$SKILLS_NIX_COUNT" ]; then
                assert_fail "Skill count mismatch: directory=$SKILLS_DIR_COUNT, symlinked=$SKILLS_NIX_COUNT"
              fi
              assert_pass "Skill counts match: $SKILLS_DIR_COUNT"

              # ─────────────────────────────────────────────────────────────────────
              # Test 2: Skills Content Validation
              # ─────────────────────────────────────────────────────────────────────
              echo ""
              echo "─── Test 2: Skills Content Validation ───"

              for skill in config/agents/skills/*/; do
                skill_name=$(basename "$skill")
                # Assertion: SKILL.md exists
                if [ ! -f "$skill/SKILL.md" ]; then
                  assert_fail "Missing SKILL.md in $skill_name"
                fi
                assert_pass "$skill_name has SKILL.md"

                # Assertion: SKILL.md is not empty
                if [ ! -s "$skill/SKILL.md" ]; then
                  assert_fail "Empty SKILL.md in $skill_name"
                fi
                assert_pass "$skill_name SKILL.md is not empty"
              done

              # ─────────────────────────────────────────────────────────────────────
              # Test 3: MCP Servers Validation
              # ─────────────────────────────────────────────────────────────────────
              echo ""
              echo "─── Test 3: MCP Servers Validation ───"

              # Extract MCP server names (portable)
              MCP_SERVERS=$(awk '/mcpServerDefs = \{/,/^  \};/' modules/home/apps/claude.nix | \
                sed -n '/^    [a-z].*= {$/p' | sed -E 's/^    ([a-z0-9-]+) =.*/\1/' | sort)
              MCP_COUNT=$(echo "$MCP_SERVERS" | wc -l | tr -d ' ')

              # Assertion: Required servers exist
              for server in memory context7 fetch repomix signet; do
                if echo "$MCP_SERVERS" | grep -q "^$server$"; then
                  assert_pass "Required MCP server: $server"
                else
                  assert_fail "Required MCP server MISSING: $server"
                fi
              done

              # Assertion: MCP count is reasonable (at least 5)
              if [ "$MCP_COUNT" -lt 5 ]; then
                assert_fail "Too few MCP servers: $MCP_COUNT (expected >= 5)"
              fi
              assert_pass "MCP server count: $MCP_COUNT"

              # ─────────────────────────────────────────────────────────────────────
              # Test 4: Settings JSON Validation
              # ─────────────────────────────────────────────────────────────────────
              echo ""
              echo "─── Test 4: Settings JSON Validation ───"

              SETTINGS="config/agents/settings/claude-code.json"

              # Assertion: JSON is valid
              if ! ${pkgs.jq}/bin/jq empty "$SETTINGS" 2>/dev/null; then
                assert_fail "Invalid JSON syntax in $SETTINGS"
              fi
              assert_pass "claude-code.json is valid JSON"

              # Assertion: hooks field exists
              if ! ${pkgs.jq}/bin/jq -e '.hooks' "$SETTINGS" >/dev/null 2>&1; then
                assert_fail "Missing 'hooks' field in settings"
              fi
              assert_pass "hooks field present"

              # Assertion: permissions field exists
              if ! ${pkgs.jq}/bin/jq -e '.permissions' "$SETTINGS" >/dev/null 2>&1; then
                assert_fail "Missing 'permissions' field in settings"
              fi
              assert_pass "permissions field present"

              # Assertion: permissions.allow is non-empty array
              ALLOW_COUNT=$(${pkgs.jq}/bin/jq '.permissions.allow | length' "$SETTINGS" 2>/dev/null)
              if [ "$ALLOW_COUNT" -lt 5 ]; then
                assert_fail "permissions.allow too small: $ALLOW_COUNT (expected >= 5)"
              fi
              assert_pass "permissions.allow has $ALLOW_COUNT entries"

              # Assertion: permissions.deny exists
              DENY_COUNT=$(${pkgs.jq}/bin/jq '.permissions.deny | length' "$SETTINGS" 2>/dev/null)
              if [ "$DENY_COUNT" -lt 3 ]; then
                assert_fail "permissions.deny too small: $DENY_COUNT (expected >= 3)"
              fi
              assert_pass "permissions.deny has $DENY_COUNT entries"

              # Assertion: All hook types defined
              for hook_type in PreToolUse PostToolUse SessionStart Stop; do
                if ${pkgs.jq}/bin/jq -e ".hooks.$hook_type" "$SETTINGS" >/dev/null 2>&1; then
                  assert_pass "Hook type defined: $hook_type"
                else
                  assert_fail "Missing hook type: $hook_type"
                fi
              done

              # ─────────────────────────────────────────────────────────────────────
              # Test 5: Hook Files Validation
              # ─────────────────────────────────────────────────────────────────────
              echo ""
              echo "─── Test 5: Hook Files Validation ───"

              # Extract hook files referenced in settings (portable)
              REFERENCED_HOOKS=$(${pkgs.jq}/bin/jq -r '.. | .command? // empty' "$SETTINGS" 2>/dev/null | \
                grep 'hooks/' | sed -E 's/.*hooks\/([a-zA-Z0-9_-]+\.(ts|sh)).*/\1/' | sort | uniq)

              for hook in $REFERENCED_HOOKS; do
                if [ -f "config/agents/hooks/$hook" ]; then
                  assert_pass "Hook exists: $hook"
                else
                  assert_fail "Hook MISSING: $hook"
                fi

                # Assertion: Hook is not empty
                if [ ! -s "config/agents/hooks/$hook" ]; then
                  assert_fail "Hook is empty: $hook"
                fi
                assert_pass "Hook not empty: $hook"
              done

              # ─────────────────────────────────────────────────────────────────────
              # Test 6: Agent Definitions Validation
              # ─────────────────────────────────────────────────────────────────────
              echo ""
              echo "─── Test 6: Agent Definitions Validation ───"

              AGENT_COUNT=0
              for agent in config/agents/agents/*.md; do
                if [ -f "$agent" ]; then
                  agent_name=$(basename "$agent")
                  AGENT_COUNT=$((AGENT_COUNT + 1))

                  # Assertion: name field exists
                  if ! grep -q "^name:" "$agent"; then
                    assert_fail "$agent_name missing 'name:' field"
                  fi
                  assert_pass "$agent_name has 'name:' field"

                  # Assertion: description field exists
                  if ! grep -q "^description:" "$agent"; then
                    assert_fail "$agent_name missing 'description:' field"
                  fi
                  assert_pass "$agent_name has 'description:' field"
                fi
              done

              # Assertion: At least some agents exist
              if [ "$AGENT_COUNT" -lt 3 ]; then
                assert_fail "Too few agents: $AGENT_COUNT (expected >= 3)"
              fi
              assert_pass "Agent count: $AGENT_COUNT"

              # ─────────────────────────────────────────────────────────────────────
              # Test 7: Commands Validation
              # ─────────────────────────────────────────────────────────────────────
              echo ""
              echo "─── Test 7: Commands Validation ───"

              CMD_COUNT=0
              for cmd in config/agents/commands/*.md; do
                if [ -f "$cmd" ]; then
                  cmd_name=$(basename "$cmd")
                  CMD_COUNT=$((CMD_COUNT + 1))

                  # Assertion: Command is not empty
                  if [ ! -s "$cmd" ]; then
                    assert_fail "Empty command file: $cmd_name"
                  fi
                  assert_pass "$cmd_name is not empty"
                fi
              done

              # Assertion: At least some commands exist
              if [ "$CMD_COUNT" -lt 3 ]; then
                assert_fail "Too few commands: $CMD_COUNT (expected >= 3)"
              fi
              assert_pass "Command count: $CMD_COUNT"

              # ─────────────────────────────────────────────────────────────────────
              # Test 8: Nix Module Validation
              # ─────────────────────────────────────────────────────────────────────
              echo ""
              echo "─── Test 8: Nix Module Validation ───"

              # Assertion: agents.nix exists
              if [ ! -f "config/agents/nix/agents.nix" ]; then
                assert_fail "Missing config/agents/nix/agents.nix"
              fi
              assert_pass "agents.nix exists"

              # Assertion: claude.nix exists
              if [ ! -f "modules/home/apps/claude.nix" ]; then
                assert_fail "Missing modules/home/apps/claude.nix"
              fi
              assert_pass "claude.nix exists"

              # Assertion: secrets.nix exists
              if [ ! -f "modules/darwin/secrets.nix" ]; then
                assert_fail "Missing modules/darwin/secrets.nix"
              fi
              assert_pass "secrets.nix exists"

              # ─────────────────────────────────────────────────────────────────────
              # Coverage Report
              # ─────────────────────────────────────────────────────────────────────
              echo ""
              echo "═══════════════════════════════════════════════════════════════"
              echo "Coverage Report"
              echo "═══════════════════════════════════════════════════════════════"

              # Calculate coverage
              COVERAGE=$((TESTS_PASSED * 100 / TESTS_TOTAL))

              echo ""
              echo "Tests passed: $TESTS_PASSED / $TESTS_TOTAL"
              echo "Coverage: $COVERAGE%"
              echo ""

              # ─────────────────────────────────────────────────────────────────────
              # Summary
              # ─────────────────────────────────────────────────────────────────────
              echo "─── Inventory ───"
              echo "Skills:   $SKILLS_DIR_COUNT defined, $SKILLS_NIX_COUNT symlinked"
              echo "MCP:      $MCP_COUNT servers"
              echo "Agents:   $AGENT_COUNT definitions"
              echo "Commands: $CMD_COUNT commands"
              echo "Hooks:    $(echo "$REFERENCED_HOOKS" | wc -w | tr -d ' ') referenced"
              echo ""

              # Block if coverage drops below 90%
              if [ "$COVERAGE" -lt 90 ]; then
                echo "ERROR: Coverage $COVERAGE% is below 90% threshold"
                exit 1
              fi

              echo "✓ All AI CLI config checks passed ($COVERAGE% coverage)"
              touch $out
            '';

        signet-factory-smoke =
          pkgs.runCommand "signet-factory-smoke"
            {
              nativeBuildInputs = [
                pkgs.bun
                pkgs.git
                pkgs.nodejs
              ];
              src = ../config/signet;
              HOME = "/tmp/signet-test";
              GIT_AUTHOR_NAME = "Signet CI";
              GIT_AUTHOR_EMAIL = "ci@signet.local";
              GIT_COMMITTER_NAME = "Signet CI";
              GIT_COMMITTER_EMAIL = "ci@signet.local";
            }
            ''
              mkdir -p $HOME
              cp -r $src signet-src && chmod -R u+w signet-src && cd signet-src
              ${pkgs.bun}/bin/bun install --frozen-lockfile

              SIGNET="$PWD/src/cli.ts"
              WORK=$(mktemp -d)
              cd "$WORK"

              test_project() {
                local type=$1
                local name="smoke-$type"
                echo "=== $type ==="
                ${pkgs.bun}/bin/bun run "$SIGNET" init "$type" "$name"
                cd "$name"
                test -f package.json || { echo "FAIL: No package.json"; exit 1; }
                test -f tsconfig.json || { echo "FAIL: No tsconfig.json"; exit 1; }
                test -d .git || { echo "FAIL: No git repo"; exit 1; }
                ${pkgs.bun}/bin/bun install --frozen-lockfile
                ${pkgs.bun}/bin/bun run typecheck
                cd ..
                rm -rf "$name"
                echo "✓ $type"
              }

              test_project library
              test_project api
              test_project ui
              test_project infra
              test_project monorepo

              echo "✓ All 5 project types passed"
              touch $out
            '';
      };
    };
}
