# NeoVim Configuration Validators
#
# Type-safe validation for NeoVim Lua configuration files.
# Validates structural patterns at Nix evaluation time.
#
# Key validations:
# - LazyVim opts merge pattern (preserves upstream integrations)
# - Required plugin files exist
# - Task runner integration (overseer, neotest, edgy)
# - Mason limited to debug adapters (linters via Nix)
# - Nix LSP configuration (nixd enabled, nil_ls disabled)
{
  lib,
  src,
  validators,
  assertions,
}:
let
  inherit (lib) filter foldl';
  inherit (validators)
    fileExists
    fileContains
    listFilesRecursive
    hasOptsMergePattern
    ;
  inherit (assertions) mkTest mkAssertion mergeTests;

  # Base paths
  nvimDir = "config/nvim";
  pluginsDir = "${nvimDir}/lua/plugins";
  testsDir = "${nvimDir}/tests";

  # ===========================================================================
  # REQUIRED FILES
  # ===========================================================================

  requiredPluginFiles = [
    "edgy.lua"
    "overseer.lua"
    "neotest.lua"
  ];

  requiredConfigFiles = [
    "${nvimDir}/lua/config/lazy.lua"
    "${nvimDir}/lua/config/options.lua"
    "${nvimDir}/lua/config/keymaps.lua"
  ];

  # ===========================================================================
  # PATTERN REQUIREMENTS
  # ===========================================================================

  # Files that MUST use opts merge pattern: opts = function(_, opts)
  optsMergeRequired = [
    "${pluginsDir}/edgy.lua"
    "${pluginsDir}/neotest.lua"
  ];

  # Patterns required in specific files
  filePatternRequirements = {
    "${pluginsDir}/overseer.lua" = [
      "dap *= *true" # DAP integration enabled
      "component_aliases" # Component aliases defined
      "OverseerRestartLast" # Custom restart command
    ];

    "${pluginsDir}/edgy.lua" = [
      "OverseerList" # Overseer panel integration
      "neotest-summary" # Neotest summary panel
      "neotest-output-panel" # Neotest output panel
    ];

    "${pluginsDir}/neotest.lua" = [
      "neotest-vitest" # Vitest adapter
    ];

    "${pluginsDir}/nvim-lspconfig.lua" = [
      "nil_ls *= *false" # nil_ls disabled
      "nixd" # nixd configured
    ];

    "${pluginsDir}/mason.lua" = [ ]; # No linter patterns (linters via Nix)
  };

  # Anti-patterns that must NOT exist
  antiPatterns = {
    "${pluginsDir}/mason.lua" = [
      ''"markdownlint"''
      ''"yamllint"''
      ''"hadolint"''
      ''"sqlfluff"''
    ];
  };

  # ===========================================================================
  # TEST GENERATORS
  # ===========================================================================

  # Generate file existence tests
  fileExistsTests =
    files:
    mergeTests (
      map (
        path:
        mkTest "neovim-file-exists:${builtins.replaceStrings [ "/" ] [ "-" ] path}" (fileExists path) true
      ) files
    );

  # Generate opts merge pattern tests
  optsMergeTests =
    files:
    mergeTests (
      map (
        path:
        mkTest "neovim-opts-merge:${
          builtins.replaceStrings [ "/" ] [ "-" ] path
        }" (hasOptsMergePattern path) true
      ) (filter fileExists files)
    );

  # Generate pattern requirement tests
  patternTests = lib.mapAttrs' (
    path: patterns:
    let
      safeName = builtins.replaceStrings [ "/" ] [ "-" ] path;
      allMatch = lib.all (pattern: fileContains path pattern) patterns;
    in
    lib.nameValuePair "neovim-patterns:${safeName}" {
      expr = fileExists path && allMatch;
      expected = true;
    }
  ) (lib.filterAttrs (_: patterns: patterns != [ ]) filePatternRequirements);

  # Generate anti-pattern tests (must NOT contain)
  antiPatternTests = lib.mapAttrs' (
    path: patterns:
    let
      safeName = builtins.replaceStrings [ "/" ] [ "-" ] path;
      noneMatch = !lib.any (pattern: fileContains path pattern) patterns;
    in
    lib.nameValuePair "neovim-no-antipattern:${safeName}" {
      expr = !fileExists path || noneMatch;
      expected = true;
    }
  ) antiPatterns;

  # Lua syntax validation (check all .lua files exist and are readable)
  luaFiles = listFilesRecursive "${nvimDir}/lua" ".lua";
  luaSyntaxTests = mergeTests (
    map (
      path:
      mkTest "neovim-lua-readable:${builtins.replaceStrings [ "/" ] [ "-" ] path}" (fileExists path) true
    ) luaFiles
  );

in
{
  # ===========================================================================
  # TESTS (for lib.debug.runTests)
  # ===========================================================================

  tests =
    # File existence
    fileExistsTests (map (f: "${pluginsDir}/${f}") requiredPluginFiles)
    // fileExistsTests requiredConfigFiles
    # Opts merge pattern
    // optsMergeTests optsMergeRequired
    # Required patterns
    // patternTests
    # Anti-patterns
    // antiPatternTests
    # Lua file readability
    // luaSyntaxTests;

  # ===========================================================================
  # ASSERTIONS (for module system)
  # ===========================================================================

  assertions =
    # Required plugin files
    (map (
      file:
      mkAssertion "neovim-plugin:${file}" (fileExists "${pluginsDir}/${file}")
        "Required NeoVim plugin file not found: ${file}"
    ) requiredPluginFiles)

    # Opts merge pattern enforcement
    ++ (map (
      path:
      mkAssertion "neovim-opts-merge:${path}" (
        !fileExists path || hasOptsMergePattern path
      ) "File ${path} must use LazyVim opts merge pattern: opts = function(_, opts)"
    ) optsMergeRequired)

    # Task runner integration (overseer in edgy)
    ++ [
      (mkAssertion "neovim-overseer-integration" (
        fileExists "${pluginsDir}/edgy.lua" && fileContains "${pluginsDir}/edgy.lua" "OverseerList"
      ) "edgy.lua must integrate Overseer panel (ft = \"OverseerList\")")

      (mkAssertion "neovim-neotest-integration" (
        fileExists "${pluginsDir}/edgy.lua"
        && fileContains "${pluginsDir}/edgy.lua" "neotest-summary"
        && fileContains "${pluginsDir}/edgy.lua" "neotest-output-panel"
      ) "edgy.lua must integrate Neotest panels")

      (mkAssertion "neovim-nixd-enabled" (
        !fileExists "${pluginsDir}/nvim-lspconfig.lua"
        || fileContains "${pluginsDir}/nvim-lspconfig.lua" "nixd"
      ) "nvim-lspconfig.lua must configure nixd LSP")

      (mkAssertion "neovim-nil-disabled" (
        !fileExists "${pluginsDir}/nvim-lspconfig.lua"
        || fileContains "${pluginsDir}/nvim-lspconfig.lua" "nil_ls *= *false"
      ) "nvim-lspconfig.lua must disable nil_ls (use nixd instead)")
    ];

  # ===========================================================================
  # METADATA
  # ===========================================================================

  meta = {
    name = "neovim";
    description = "NeoVim configuration validation";
    fileCount = builtins.length luaFiles;
    requiredPlugins = requiredPluginFiles;
  };
}
