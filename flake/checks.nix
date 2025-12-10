# Custom checks - preserves existing ai-cli-config validation
{...}: {
  perSystem = {pkgs, ...}: {
    checks = {
      # Signet TypeScript type checking
      signet-typecheck =
        pkgs.runCommand "signet-typecheck"
        {
          nativeBuildInputs = [pkgs.bun pkgs.nodejs];
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

      # Validate AI CLI configuration files (single source of truth)
      ai-cli-config =
        pkgs.runCommand "ai-cli-config-check"
        {
          nativeBuildInputs = [pkgs.jq];
          src = ../.;
        }
        ''
          cd $src

          # Validate JSON configs
          for json in config/agents/settings/*.json config/agents/settings.json; do
            if [ -f "$json" ]; then
              echo "✓ $json"
              ${pkgs.jq}/bin/jq . "$json" > /dev/null
            fi
          done

          # Validate skills
          for skill in config/agents/skills/*/; do
            test -f "$skill/SKILL.md" || { echo "Missing SKILL.md in $skill"; exit 1; }
            echo "✓ $skill"
          done

          # Validate remaining commands (infrastructure actions)
          for cmd in config/agents/commands/*.md; do
            if [ -f "$cmd" ]; then
              echo "✓ $cmd"
            fi
          done

          # Validate agents
          for agent in config/agents/agents/*.md; do
            if [ -f "$agent" ]; then
              # Check for required frontmatter
              grep -q "^name:" "$agent" || { echo "Missing 'name:' in $agent"; exit 1; }
              grep -q "^description:" "$agent" || { echo "Missing 'description:' in $agent"; exit 1; }
              echo "✓ $agent"
            fi
          done

          # Validate hooks referenced in settings exist
          for hook in unified-guard.ts unified-polish.ts enforce-versions.ts \
                      session-start.sh session-stop.sh verification-gate.ts; do
            test -f "config/agents/hooks/$hook" || { echo "Missing hook: $hook"; exit 1; }
            echo "✓ hooks/$hook"
          done

          # Output coverage summary
          echo ""
          echo "Coverage: $(ls config/agents/skills/ | wc -l | tr -d ' ') skills"
          echo "Coverage: $(ls config/agents/agents/*.md 2>/dev/null | wc -l | tr -d ' ') agents"
          echo "Coverage: $(ls config/agents/commands/*.md 2>/dev/null | wc -l | tr -d ' ') commands"
          echo "Coverage: $(ls config/agents/hooks/*.ts config/agents/hooks/*.sh 2>/dev/null | wc -l | tr -d ' ') hooks"

          echo ""
          echo "All AI CLI config checks passed"
          touch $out
        '';
    };
  };
}
