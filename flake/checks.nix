# Custom checks - preserves existing ai-cli-config validation
{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        # Validate AI CLI configuration files (single source of truth)
        ai-cli-config =
          pkgs.runCommand "ai-cli-config-check"
            {
              nativeBuildInputs = [ pkgs.jq ];
              src = ../.;
            }
            ''
              cd $src

              # Validate JSON configs
              for json in config/agents/settings/*.json config/agents/mcp-servers.json; do
                echo "✓ $json"
                ${pkgs.jq}/bin/jq . "$json" > /dev/null
              done

              # Validate skills
              for skill in config/agents/skills/*/; do
                test -f "$skill/SKILL.md" || { echo "Missing SKILL.md in $skill"; exit 1; }
                echo "✓ $skill"
              done

              # Validate commands
              for cmd in config/agents/commands/*.md; do
                test -f "$cmd" || { echo "Missing command: $cmd"; exit 1; }
                echo "✓ $cmd"
              done

              # Validate hooks referenced in settings exist
              for hook in unified-guard.ts unified-polish.ts enforce-versions.ts \
                          session-start.sh session-stop.sh verification-gate.ts assumption-detector.ts; do
                test -f "config/agents/hooks/$hook" || { echo "Missing hook: $hook"; exit 1; }
                echo "✓ hooks/$hook"
              done

              # Output coverage summary
              echo ""
              echo "Coverage: $(ls config/agents/skills/ | wc -l | tr -d ' ') skills"
              echo "Coverage: $(ls config/agents/commands/*.md | wc -l | tr -d ' ') commands"
              echo "Coverage: $(ls config/agents/hooks/*.ts config/agents/hooks/*.sh 2>/dev/null | wc -l | tr -d ' ') hooks"

              echo ""
              echo "All AI CLI config checks passed"
              touch $out
            '';
      };
    };
}
