# Assertion Builders - Reusable Type-Safe Validators
#
# DRY assertion patterns for consistent error messages and test structure.
# All functions return either:
# - { assertion, message } for module-system assertions
# - { expr, expected } for lib.debug.runTests
{ lib }:
let
  inherit (lib) assertMsg concatStringsSep;
  inherit (builtins)
    typeOf
    isAttrs
    isList
    isString
    match
    ;

in
rec {
  # ===========================================================================
  # ASSERTION BUILDERS (for module system)
  # ===========================================================================

  # Build a named assertion with consistent formatting
  # Usage: mkAssertion "neovim.opts-merge" (hasPattern ...) "must use opts merge pattern"
  mkAssertion = name: condition: message: {
    assertion = condition;
    message = "[${name}] ${message}";
  };

  # Assert file exists in source tree
  # Usage: assertFileExists src "config/nvim/lua/plugins/overseer.lua"
  assertFileExists =
    src: path:
    let
      fullPath = "${src}/${path}";
      exists = builtins.pathExists fullPath;
    in
    mkAssertion "file-exists:${path}" exists "Required file not found: ${path}";

  # Assert file contains pattern (regex)
  # Usage: assertFileContains src "foo.lua" "opts = function"
  assertFileContains =
    src: path: pattern:
    let
      fullPath = "${src}/${path}";
      exists = builtins.pathExists fullPath;
      content = if exists then builtins.readFile fullPath else "";
      hasPattern = builtins.match ".*${pattern}.*" content != null;
    in
    mkAssertion "file-contains:${path}" (
      exists && hasPattern
    ) "File '${path}' must contain pattern: ${pattern}";

  # Assert file does NOT contain pattern (for anti-patterns)
  # Usage: assertFileNotContains src "foo.lua" "deprecated_function"
  assertFileNotContains =
    src: path: pattern:
    let
      fullPath = "${src}/${path}";
      exists = builtins.pathExists fullPath;
      content = if exists then builtins.readFile fullPath else "";
      hasPattern = builtins.match ".*${pattern}.*" content != null;
    in
    mkAssertion "file-not-contains:${path}" (
      !exists || !hasPattern
    ) "File '${path}' must NOT contain anti-pattern: ${pattern}";

  # ===========================================================================
  # TEST BUILDERS (for lib.debug.runTests)
  # ===========================================================================

  # Build a named test case
  # Usage: mkTest "overseer-exists" (pathExists ...) true
  mkTest = name: expr: expected: {
    ${name} = { inherit expr expected; };
  };

  # Test that file exists
  testFileExists =
    src: path:
    mkTest "file-exists:${
      builtins.replaceStrings [ "/" ] [ "-" ] path
    }" (builtins.pathExists "${src}/${path}") true;

  # Test that file contains pattern
  testFileContains =
    src: path: pattern:
    let
      fullPath = "${src}/${path}";
      exists = builtins.pathExists fullPath;
      content = if exists then builtins.readFile fullPath else "";
    in
    mkTest "file-contains:${builtins.replaceStrings [ "/" ] [ "-" ] path}:${
      builtins.substring 0 20 pattern
    }" (exists && builtins.match ".*${pattern}.*" content != null) true;

  # Test that file does NOT contain pattern
  testFileNotContains =
    src: path: pattern:
    let
      fullPath = "${src}/${path}";
      exists = builtins.pathExists fullPath;
      content = if exists then builtins.readFile fullPath else "";
    in
    mkTest "file-not-contains:${builtins.replaceStrings [ "/" ] [ "-" ] path}:${
      builtins.substring 0 20 pattern
    }" (!exists || builtins.match ".*${pattern}.*" content == null) true;

  # ===========================================================================
  # BATCH OPERATIONS (DRY helpers)
  # ===========================================================================

  # Apply multiple file existence checks
  # Usage: assertFilesExist src [ "a.lua" "b.lua" ]
  assertFilesExist = src: paths: map (path: assertFileExists src path) paths;

  # Apply multiple pattern checks to same file
  # Usage: assertFileContainsAll src "foo.lua" [ "pattern1" "pattern2" ]
  assertFileContainsAll =
    src: path: patterns:
    map (pattern: assertFileContains src path pattern) patterns;

  # Merge multiple test attrsets
  # Usage: mergeTests [ (testFileExists ...) (testFileContains ...) ]
  mergeTests = testList: lib.foldl' (acc: t: acc // t) { } testList;

  # ===========================================================================
  # SPECIALIZED VALIDATORS
  # ===========================================================================

  # Validate Lua file has LazyVim opts merge pattern
  # The pattern `opts = function(_, opts)` preserves upstream integrations
  assertOptsPattern =
    src: path:
    assertFileContains src path
      ''opts[[:space:]]*=[[:space:]]*function[[:space:]]*\([[:space:]]*_[[:space:]]*,[[:space:]]*opts[[:space:]]*\)'';

  testOptsPattern =
    src: path:
    let
      fullPath = "${src}/${path}";
      exists = builtins.pathExists fullPath;
      content = if exists then builtins.readFile fullPath else "";
      # Simpler pattern for Nix regex (POSIX ERE)
      hasPattern = builtins.match ".*opts *= *function *\\( *_ *, *opts *\\).*" content != null;
    in
    mkTest "opts-merge-pattern:${builtins.replaceStrings [ "/" ] [ "-" ] path}" (
      exists && hasPattern
    ) true;

  # Validate no deprecated patterns exist
  assertNoDeprecated =
    src: path: deprecatedPatterns:
    map (pattern: assertFileNotContains src path pattern) deprecatedPatterns;
}
