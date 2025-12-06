# Global git hooks for conventional commits
# Applies to all repos unless they have their own hook manager (lefthook/husky)
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.modules.home.tools.git-hooks = {
    enable = mkEnableOption "global git hooks";
  };

  config = mkIf config.modules.home.tools.git-hooks.enable {
    # Set global hooks path
    programs.git.extraConfig.core.hooksPath = "${config.home.homeDirectory}/.config/git/hooks";

    # Create commit-msg hook
    home.file.".config/git/hooks/commit-msg" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Global commit-msg hook - validates conventional commits
        # Managed by: ~/dotfiles/modules/home/tools/git-hooks.nix

        # If repo has its own commit-msg hook, delegate to it
        REPO_HOOK=".git/hooks/commit-msg"
        if [[ -x "$REPO_HOOK" ]]; then
          exec "$REPO_HOOK" "$@"
        fi

        # If repo has a hook manager config but no hook installed yet, skip
        # (user should run `lefthook install` or `npx husky install`)
        if [[ -f "lefthook.yml" ]] || [[ -f ".lefthook.yml" ]] || [[ -d ".husky" ]]; then
          exit 0
        fi

        MSG=$(cat "$1")

        # Skip merge commits
        if echo "$MSG" | grep -qE "^Merge "; then
          exit 0
        fi

        # Conventional commit regex
        # Format: type(scope)!: description
        # Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
        PATTERN="^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?(!)?: .+"

        if ! echo "$MSG" | grep -qE "$PATTERN"; then
          echo ""
          echo "❌ Commit message does not follow conventional commits format"
          echo ""
          echo "Format: type(scope): description"
          echo ""
          echo "Types:"
          echo "  feat     - New feature"
          echo "  fix      - Bug fix"
          echo "  docs     - Documentation only"
          echo "  style    - Code style (formatting, semicolons)"
          echo "  refactor - Code change that neither fixes nor adds"
          echo "  perf     - Performance improvement"
          echo "  test     - Adding or updating tests"
          echo "  build    - Build system or dependencies"
          echo "  ci       - CI/CD configuration"
          echo "  chore    - Maintenance tasks"
          echo "  revert   - Revert previous commit"
          echo ""
          echo "Examples:"
          echo "  feat(auth): add login page"
          echo "  fix: resolve memory leak"
          echo "  chore(deps): update dependencies"
          echo ""
          echo "Your message:"
          echo "  $MSG"
          echo ""
          exit 1
        fi
      '';
    };
  };
}
