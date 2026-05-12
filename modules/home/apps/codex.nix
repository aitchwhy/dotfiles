# Codex CLI Multi-Account Launcher (cx) + Harness
#
# Phase A: cx FCF picker mirroring cc. CODEX_HOME=$HOME/.codex-<name>
# isolates each account's auth.json, config.toml, history, sessions.
#
# Phase B (May 2026): symlink farm for shared skills/agents and per-account
# AGENTS.md + activation hook that deploys the generated config.toml.
#
# References:
#   config/quality/docs/adr/015-codex-harness-port.md
#   Linear: Codex Harness Parity project
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mkEnableOption
    mkIf
    ;

  # ═══════════════════════════════════════════════════════════════════════════
  # CODEX ACCOUNT REGISTRY SSOT
  # Drives: cx fzf picker, dispatch case, status recipe, per-account symlinks,
  # activation hook target paths.
  # ═══════════════════════════════════════════════════════════════════════════

  codexAccountDefs = [
    {
      name = "codex-max-1";
      codexHome = ".codex-max-1";
      description = "Codex Max — primary";
      email = "hank.lee.qed@gmail.com";
      authMethod = "chatgpt-oauth";
    }
    {
      name = "codex-max-2";
      codexHome = ".codex-max-2";
      description = "Codex Max — secondary";
      email = "hank@told.one";
      authMethod = "chatgpt-oauth";
    }
  ];

  # Bash list of CODEX_HOME absolute paths for activation hooks
  codexHomePaths = concatStringsSep " " (map (acct: ''"$HOME/${acct.codexHome}"'') codexAccountDefs);

  # ═══════════════════════════════════════════════════════════════════════════
  # PER-ACCOUNT SYMLINK FARM
  # Each ~/.codex-<acct>/AGENTS.md → ~/dotfiles/AGENTS.md (the canonical
  # Codex instruction set written in Phase B T7).
  # ═══════════════════════════════════════════════════════════════════════════

  perAccountSymlinks = builtins.listToAttrs (
    map (acct: {
      name = "${acct.codexHome}/AGENTS.md";
      value = {
        source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/AGENTS.md";
      };
    }) codexAccountDefs
  );

  # ═══════════════════════════════════════════════════════════════════════════
  # USER-SCOPED .agents/skills SYMLINK
  # Codex resolves skills from ~/.agents/skills/ at user scope (agentskills.io
  # standard, Codex skills docs). Shared across all accounts; dotfiles owns
  # the source of truth.
  #
  # Subagents do NOT live here. Per Codex docs, subagents are discovered at
  # $CODEX_HOME/agents/ (user scope) and $CWD/.codex/agents/ (project scope).
  # See perAccountAgentSymlinks below for the per-account user-scope farm.
  # ═══════════════════════════════════════════════════════════════════════════

  userAgentsSymlinks = {
    ".agents/skills" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/claude-code/skills";
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # PER-ACCOUNT SUBAGENT FARM
  # Codex's user-scope subagent path is $CODEX_HOME/agents/*.toml. Enumerate
  # config/claude-code/agents/*.toml and symlink each one into every account's
  # agents dir. Dropping a new TOML file auto-deploys on next `just switch`.
  # ═══════════════════════════════════════════════════════════════════════════

  agentTomlNames = builtins.attrNames (
    lib.filterAttrs (n: t: t == "regular" && lib.hasSuffix ".toml" n) (
      builtins.readDir ../../../config/claude-code/agents
    )
  );

  perAccountAgentSymlinks = builtins.listToAttrs (
    lib.concatMap (
      acct:
      map (fname: {
        name = "${acct.codexHome}/agents/${fname}";
        value = {
          source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/claude-code/agents/${fname}";
        };
      }) agentTomlNames
    ) codexAccountDefs
  );

  # ═══════════════════════════════════════════════════════════════════════════
  # `cx` RECIPE GENERATION (mirrors claude.nix:411–576)
  # ═══════════════════════════════════════════════════════════════════════════

  cxRecipeContent =
    let
      # Pad to 13 chars so "codex-max-N" + description columns line up
      padName = name: name + builtins.substring 0 (13 - builtins.stringLength name) "             ";

      fzfEntries = map (
        acct:
        let
          emailSuffix = if acct.email != null then " (${acct.email})" else "";
        in
        ''"${padName acct.name}${acct.description}${emailSuffix}"''
      ) codexAccountDefs;

      helpEntries = map (acct: ''echo "  ${padName acct.name}${acct.description}"'') codexAccountDefs;

      # REF_API_KEY resolution: AWS Secrets Manager first (auth-rotated),
      # local file fallback for offline/SSO-expired use (CC-45). Both halves
      # tolerate failure with `|| true` so codex still launches; missing
      # bearer token degrades to no-MCP-ref instead of breaking the picker.
      refKeyResolve = ''$(aws secretsmanager get-secret-value --secret-id told/vendor/ref/api-key --profile AdministratorAccess-952084167040 --query SecretString --output text 2>/dev/null || cat "$HOME/.config/mcp/ref-api-key" 2>/dev/null || true)'';

      # Each dispatch branch exports REF_API_KEY so the codex MCP `ref`
      # server's bearer_token_env_var resolves at runtime.
      mkCaseBranch =
        acct:
        ''${acct.name}) REF_API_KEY="${refKeyResolve}" AI_ACCOUNT="${acct.name}" CODEX_HOME="$HOME/${acct.codexHome}" codex "$@" ;;'';

      # Default account used when $1 isn't a recognized account or keyword —
      # the passthrough case below restores $1 to "$@" and launches with this
      # account's env. Lets `cx mcp login ref` Just Work.
      defaultAcct = builtins.head codexAccountDefs;

      defaultPassthroughBranch = ''*) set -- "$account" "$@"; REF_API_KEY="${refKeyResolve}" AI_ACCOUNT="${defaultAcct.name}" CODEX_HOME="$HOME/${defaultAcct.codexHome}" codex "$@" ;;'';

      caseBranches = map mkCaseBranch codexAccountDefs;

      mkStatusEntry =
        acct:
        let
          emailSuffix = if acct.email != null then " (${acct.email})" else "";
          header = ''echo "=== ${acct.name}${emailSuffix} ==="'';
        in
        [
          header
          ''CODEX_HOME="$HOME/${acct.codexHome}" codex login status 2>&1 || true''
          ''echo ""''
        ];

      statusEntries = builtins.concatLists (map mkStatusEntry codexAccountDefs);
    in
    concatStringsSep "\n" (
      [
        "# ─── Codex CLI Multi-Account Launcher (cx) ──────────────────────────────"
        "# Generated by Nix from codexAccountDefs SSOT in modules/home/apps/codex.nix."
        ""
        "# Launch Codex CLI with account selection"
        "[no-cd]"
        ''cx *args="":''
        "    #!/usr/bin/env bash"
        "    set -euo pipefail"
        "    # just doesn't pass variadic recipe args to shebang scripts as $1, $2."
        "    # Use {{args}} interpolation to populate bash positional args."
        "    set -- {{args}}"
        "    account=\"\${1:-}\""
        "    shift || true"
        ""
        "    if [[ -z \"$account\" ]]; then"
        "      account=$(printf '%s\\n' \\"
      ]
      ++ map (e: "        ${e} \\") (
        fzfEntries
        ++ [
          ''"---"''
          ''"status   Auth status for all accounts"''
        ]
      )
      ++ [
        "        | fzf --reverse --height=40% --prompt=\"cx > \" \\"
        "        | awk '{print $1}')"
        "      [[ -z \"$account\" || \"$account\" == \"---\" ]] && exit 1"
        "    fi"
        ""
        "    [[ \"$account\" != \"status\" && \"$account\" != \"help\" ]] && echo \"-> cx $account\" >&2"
        ""
        "    case \"$account\" in"
        "      help|-h|--help)"
        "        echo \"Usage: just -g cx [account] [codex args...]\""
        "        echo \"\""
        "        echo \"Accounts:\""
      ]
      ++ map (e: "        ${e}") helpEntries
      ++ [
        "        echo \"\""
        "        echo \"Commands:\""
        "        echo \"  just -g cx             fzf account picker\""
        "        echo \"  just -g cx status      auth status for all accounts\""
        "        echo \"  just -g cx <acct> ...  launch codex with account + passthrough args\""
        "        exit 0 ;;"
      ]
      ++ map (e: "      ${e}") caseBranches
      ++ [
        "      status)"
      ]
      ++ map (e: "        ${e}") statusEntries
      ++ [
        "        ;;"
        "      ${defaultPassthroughBranch}"
        "    esac"
        ""
        "# Show auth status for all Codex accounts"
        "[no-cd]"
        "cx-status:"
        "    #!/usr/bin/env bash"
        "    set -euo pipefail"
      ]
      ++ map (e: "    ${e}") statusEntries
      ++ [ "" ]
    );

  # ═══════════════════════════════════════════════════════════════════════════
  # `cx-net` + `cx-net-creds` RECIPE GENERATION (CC-94)
  #
  # Two recipes that share the `cx` account-dispatch shape but inject sandbox
  # overrides:
  #   -c sandbox_workspace_write.network_access=true
  #   -c "sandbox_workspace_write.writable_roots=[…]"   (per-recipe scoped)
  #
  # Threat model:
  #   cx-net        — unattended runs. Network on. writable_roots widens ONLY
  #                   the pnpm content-addressed store (self-healing on
  #                   corruption). AWS SSO cache + Pulumi creds remain
  #                   readable (default) but NOT writable — codex can `aws
  #                   sso login` / `pulumi whoami` but cannot tamper with the
  #                   credential files.
  #   cx-net-creds  — superset: also includes ~/.config/gh as RW so `gh auth
  #                   login` / `gh pr create` (both write auth state) work.
  #                   Operator-attended; the elevated credential surface is
  #                   visible at the recipe name.
  #
  # writable_roots paths use bash-time `$HOME` expansion so the recipe
  # resolves correctly per logged-in user. Each path is added with
  # `read_write` permission (codex's default `writable_roots` semantics).
  # ═══════════════════════════════════════════════════════════════════════════

  cxNetRecipeContent =
    let
      # Same helpers as cxRecipeContent (re-derived for scope; intentional
      # duplication avoids restructuring the working `cx` recipe).
      padName = name: name + builtins.substring 0 (13 - builtins.stringLength name) "             ";

      fzfEntries = map (
        acct:
        let
          emailSuffix = if acct.email != null then " (${acct.email})" else "";
        in
        ''"${padName acct.name}${acct.description}${emailSuffix}"''
      ) codexAccountDefs;

      helpEntries = map (acct: ''echo "  ${padName acct.name}${acct.description}"'') codexAccountDefs;

      refKeyResolve = ''$(aws secretsmanager get-secret-value --secret-id told/vendor/ref/api-key --profile AdministratorAccess-952084167040 --query SecretString --output text 2>/dev/null || cat "$HOME/.config/mcp/ref-api-key" 2>/dev/null || true)'';

      defaultAcct = builtins.head codexAccountDefs;

      mkStatusEntry =
        acct:
        let
          emailSuffix = if acct.email != null then " (${acct.email})" else "";
          header = ''echo "=== ${acct.name}${emailSuffix} ==="'';
        in
        [
          header
          ''CODEX_HOME="$HOME/${acct.codexHome}" codex login status 2>&1 || true''
          ''echo ""''
        ];

      statusEntries = builtins.concatLists (map mkStatusEntry codexAccountDefs);

      # Render a TOML array literal whose elements expand `$HOME` at bash
      # time. Result e.g. `[\"$HOME/.local/share/pnpm/store\"]` — the
      # backslash-quoted `\"` survives nix string-rendering; bash interprets
      # the surrounding double-quotes as a single argv element; codex
      # receives `["/Users/hank/.local/share/pnpm/store"]` as a TOML array.
      mkWritableRootsArr =
        writableRoots: "[" + (concatStringsSep "," (map (p: ''\"'' + p + ''\"'') writableRoots)) + "]";

      mkCxNetCaseBranch =
        writableRoots: acct:
        let
          rootsArr = mkWritableRootsArr writableRoots;
        in
        ''${acct.name}) REF_API_KEY="${refKeyResolve}" AI_ACCOUNT="${acct.name}" CODEX_HOME="$HOME/${acct.codexHome}" codex -c sandbox_workspace_write.network_access=true -c "sandbox_workspace_write.writable_roots=${rootsArr}" "$@" ;;'';

      mkCxNetDefaultPassthrough =
        writableRoots:
        let
          rootsArr = mkWritableRootsArr writableRoots;
        in
        ''*) set -- "$account" "$@"; REF_API_KEY="${refKeyResolve}" AI_ACCOUNT="${defaultAcct.name}" CODEX_HOME="$HOME/${defaultAcct.codexHome}" codex -c sandbox_workspace_write.network_access=true -c "sandbox_workspace_write.writable_roots=${rootsArr}" "$@" ;;'';

      # Per-recipe scoped writable_roots. `$HOME` is bash-literal here (nix
      # ''...'' does NOT interpolate `$`), so it expands at recipe runtime.
      cxNetWritableRoots = [
        "$HOME/.local/share/pnpm/store"
      ];

      cxNetCredsWritableRoots = [
        "$HOME/.local/share/pnpm/store"
        "$HOME/.config/gh"
      ];

      mkCxNetRecipe =
        recipeName: writableRoots:
        let
          caseBranches = map (mkCxNetCaseBranch writableRoots) codexAccountDefs;
          defaultPassthroughBranch = mkCxNetDefaultPassthrough writableRoots;
        in
        concatStringsSep "\n" (
          [
            ""
            "# ─── Codex CLI Multi-Account Launcher (${recipeName}) ──────────────────"
            "# Generated by Nix from codexAccountDefs SSOT in modules/home/apps/codex.nix."
            "# Mirrors `cx` but with sandbox network access + scoped writable_roots."
            "# Source: CC-94 (closes CC-91 Section F unattended-multi-step gap)."
            ""
            "[no-cd]"
            ''${recipeName} *args="":''
            "    #!/usr/bin/env bash"
            "    set -euo pipefail"
            "    set -- {{args}}"
            "    account=\"\${1:-}\""
            "    shift || true"
            ""
            "    if [[ -z \"$account\" ]]; then"
            "      account=$(printf '%s\\n' \\"
          ]
          ++ map (e: "        ${e} \\") (
            fzfEntries
            ++ [
              ''"---"''
              ''"status   Auth status for all accounts"''
            ]
          )
          ++ [
            "        | fzf --reverse --height=40% --prompt=\"${recipeName} > \" \\"
            "        | awk '{print $1}')"
            "      [[ -z \"$account\" || \"$account\" == \"---\" ]] && exit 1"
            "    fi"
            ""
            "    [[ \"$account\" != \"status\" && \"$account\" != \"help\" ]] && echo \"-> ${recipeName} $account (net=on, writable_roots scoped)\" >&2"
            ""
            "    case \"$account\" in"
            "      help|-h|--help)"
            "        echo \"Usage: just -g ${recipeName} [account] [codex args...]\""
            "        echo \"\""
            "        echo \"Accounts:\""
          ]
          ++ map (e: "        ${e}") helpEntries
          ++ [
            "        echo \"\""
            "        echo \"Commands:\""
            "        echo \"  just -g ${recipeName}             fzf account picker\""
            "        echo \"  just -g ${recipeName} status      auth status for all accounts\""
            "        echo \"  just -g ${recipeName} <acct> ...  launch codex with account + sandbox network + scoped writable_roots\""
            "        echo \"\""
            "        echo \"Scoped writable_roots (in addition to \\$CWD):\""
          ]
          ++ map (p: "        echo \"  ${p}\"") writableRoots
          ++ [
            "        exit 0 ;;"
          ]
          ++ map (e: "      ${e}") caseBranches
          ++ [
            "      status)"
          ]
          ++ map (e: "        ${e}") statusEntries
          ++ [
            "        ;;"
            "      ${defaultPassthroughBranch}"
            "    esac"
            ""
          ]
        );
    in
    (mkCxNetRecipe "cx-net" cxNetWritableRoots)
    + "\n"
    + (mkCxNetRecipe "cx-net-creds" cxNetCredsWritableRoots);
in
{
  options.modules.home.apps.codex = {
    enable = mkEnableOption "Codex CLI multi-account launcher (cx) + harness symlinks";

    cxJustRecipes = lib.mkOption {
      type = lib.types.str;
      default = cxRecipeContent;
      readOnly = true;
      description = "Generated `cx` recipes (without shared header) for the global justfile";
    };

    cxNetJustRecipes = lib.mkOption {
      type = lib.types.str;
      default = cxNetRecipeContent;
      readOnly = true;
      description = "Generated `cx-net` + `cx-net-creds` recipes (CC-94) for the global justfile";
    };
  };

  config = mkIf config.modules.home.apps.codex.enable {
    # Per-account AGENTS.md symlinks (~/.codex-max-N/AGENTS.md → ~/dotfiles/AGENTS.md)
    # + user-scope skills symlink (~/.agents/skills) + per-account subagent
    # symlinks (~/.codex-max-N/agents/<name>.toml).
    home.file = perAccountSymlinks // userAgentsSymlinks // perAccountAgentSymlinks;

    # Activation hook: deploy the generated config.toml to each CODEX_HOME.
    # MUST run AFTER `generateQuality` (defined in claude.nix) — otherwise
    # we deploy the stale on-disk config.toml from before the latest
    # `bun run generate`. Pin the order via entryAfter.
    home.activation.deployCodexConfig = lib.hm.dag.entryAfter [ "generateQuality" ] ''
      GENERATED="${config.home.homeDirectory}/dotfiles/config/quality/generated/codex/config.toml"
      if [ ! -f "$GENERATED" ]; then
        echo "Codex: generated config.toml not found at $GENERATED — run 'bun run generate' in config/quality first."
        exit 0
      fi
      for codex_home in ${codexHomePaths}; do
        mkdir -p "$codex_home"
        TARGET="$codex_home/config.toml"
        # Only rewrite when content changed (avoid touch-storms on activation).
        if [ ! -f "$TARGET" ] || ! /usr/bin/cmp -s "$GENERATED" "$TARGET"; then
          /bin/cp "$GENERATED" "$TARGET"
          echo "Codex: deployed config.toml → $TARGET"
        fi
      done
    '';
  };
}
