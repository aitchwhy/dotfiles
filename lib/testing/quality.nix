# Quality System Validators
#
# Type-safe validation for the TypeScript-based quality system.
# Validates at Nix evaluation time that required files exist.
#
# Note: TypeScript type checking is done via a separate derivation
# since it requires the bun runtime.
{
  lib,
  src,
  validators,
  assertions,
}:
let
  inherit (validators) fileExists listFilesRecursive;
  inherit (assertions) mkTest mkAssertion mergeTests;

  # Base paths
  qualityDir = "config/quality";

  # ===========================================================================
  # REQUIRED FILES
  # ===========================================================================

  requiredFiles = [
    "${qualityDir}/package.json"
    "${qualityDir}/tsconfig.json"
    "${qualityDir}/src/index.ts"
  ];

  requiredDirs = [
    "${qualityDir}/src/skills"
    "${qualityDir}/src/hooks"
    "${qualityDir}/src/personas"
  ];

  # ===========================================================================
  # TEST GENERATORS
  # ===========================================================================

  fileExistsTests = mergeTests (
    map (
      path:
      mkTest "quality-file-exists:${builtins.replaceStrings [ "/" ] [ "-" ] path}" (fileExists path) true
    ) requiredFiles
  );

  # Check directories exist by checking for at least one file
  dirExistsTests = mergeTests (
    map (
      dir:
      let
        files = listFilesRecursive dir ".ts";
      in
      mkTest "quality-dir-has-files:${builtins.replaceStrings [ "/" ] [ "-" ] dir}" (files != [ ]) true
    ) requiredDirs
  );

in
{
  # ===========================================================================
  # TESTS (for lib.debug.runTests)
  # ===========================================================================

  tests = fileExistsTests // dirExistsTests;

  # ===========================================================================
  # ASSERTIONS (for module system)
  # ===========================================================================

  assertions =
    (map (
      path:
      mkAssertion "quality-file:${path}" (fileExists path)
        "Required quality system file not found: ${path}"
    ) requiredFiles)

    ++ (map (
      dir:
      let
        files = listFilesRecursive dir ".ts";
      in
      mkAssertion "quality-dir:${dir}" (
        files != [ ]
      ) "Quality system directory must contain TypeScript files: ${dir}"
    ) requiredDirs);

  # ===========================================================================
  # METADATA
  # ===========================================================================

  meta = {
    name = "quality";
    description = "Quality system configuration validation";
    baseDir = qualityDir;
  };
}
