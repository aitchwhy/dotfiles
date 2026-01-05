# Domain Validators - File System and Content Validation
#
# Pure Nix functions for validating configuration files.
# No bash scripts - everything evaluates at Nix evaluation time.
{ lib, src }:
let
  inherit (builtins)
    pathExists
    readFile
    readDir
    attrNames
    filter
    match
    ;
  inherit (lib)
    filterAttrs
    mapAttrsToList
    flatten
    hasSuffix
    ;

in
rec {
  # ===========================================================================
  # FILE SYSTEM OPERATIONS
  # ===========================================================================

  # Check if path exists relative to src
  fileExists = path: pathExists "${src}/${path}";

  # Read file content (returns "" if not exists)
  readFileOr =
    path: default:
    let
      fullPath = "${src}/${path}";
    in
    if pathExists fullPath then readFile fullPath else default;

  # Read file content (throws if not exists)
  readFileSafe =
    path:
    let
      fullPath = "${src}/${path}";
    in
    if pathExists fullPath then readFile fullPath else throw "File not found: ${path}";

  # List files in directory with extension filter
  # Usage: listFiles "config/nvim/lua/plugins" ".lua"
  listFiles =
    dir: ext:
    let
      fullDir = "${src}/${dir}";
      entries = if pathExists fullDir then readDir fullDir else { };
      files = filterAttrs (_: type: type == "regular") entries;
      filtered = filter (name: hasSuffix ext name) (attrNames files);
    in
    map (name: "${dir}/${name}") filtered;

  # Recursively list all files with extension
  # Usage: listFilesRecursive "config/nvim/lua" ".lua"
  listFilesRecursive =
    dir: ext:
    let
      fullDir = "${src}/${dir}";
      entries = if pathExists fullDir then readDir fullDir else { };
      files = filterAttrs (_: type: type == "regular") entries;
      dirs = filterAttrs (_: type: type == "directory") entries;

      currentFiles = filter (name: hasSuffix ext name) (attrNames files);
      currentPaths = map (name: "${dir}/${name}") currentFiles;

      subPaths = flatten (mapAttrsToList (name: _: listFilesRecursive "${dir}/${name}" ext) dirs);
    in
    currentPaths ++ subPaths;

  # ===========================================================================
  # CONTENT VALIDATION
  # ===========================================================================

  # Check if file contains pattern (POSIX ERE regex)
  fileContains =
    path: pattern:
    let
      content = readFileOr path "";
    in
    match ".*${pattern}.*" content != null;

  # Check if file contains literal string
  fileContainsLiteral =
    path: needle:
    let
      content = readFileOr path "";
      # Escape regex special chars for literal match
      escaped = lib.escapeRegex needle;
    in
    match ".*${escaped}.*" content != null;

  # Check multiple patterns (AND - all must match)
  fileContainsAll = path: patterns: lib.all (pattern: fileContains path pattern) patterns;

  # Check multiple patterns (OR - any must match)
  fileContainsAny = path: patterns: lib.any (pattern: fileContains path pattern) patterns;

  # ===========================================================================
  # LUA-SPECIFIC VALIDATORS
  # ===========================================================================

  # Check for LazyVim opts merge pattern
  # Critical: `opts = function(_, opts)` preserves upstream integrations
  hasOptsMergePattern = path: fileContains path "opts *= *function *\\( *_ *, *opts *\\)";

  # Check for fresh opts pattern (ANTI-PATTERN)
  # Bad: `opts = function()` loses LazyVim integrations
  hasFreshOptsPattern =
    path: fileContains path "opts *= *function *\\( *\\)" && !(hasOptsMergePattern path);

  # Validate all Lua plugin files use opts merge pattern where applicable
  validateLuaPlugins =
    dir:
    let
      files = listFilesRecursive dir ".lua";
      # Files that define opts should use merge pattern
      hasOpts = path: fileContains path "opts *=";
      filesWithOpts = filter hasOpts files;
      violations = filter (path: hasFreshOptsPattern path) filesWithOpts;
    in
    {
      valid = violations == [ ];
      violations = violations;
      message =
        if violations == [ ] then
          "All Lua plugins use correct opts pattern"
        else
          "Files using fresh opts pattern (should use merge): ${toString violations}";
    };

  # ===========================================================================
  # KDL-SPECIFIC VALIDATORS (Zellij)
  # ===========================================================================

  # Check for Alt+Arrow bindings (conflict with macOS word navigation)
  hasAltArrowBindings =
    path:
    fileContainsAny path [
      ''bind "Alt left"''
      ''bind "Alt right"''
      ''bind "Alt up"''
      ''bind "Alt down"''
    ];

  # ===========================================================================
  # BATCH VALIDATORS
  # ===========================================================================

  # Validate multiple files exist
  allFilesExist =
    paths:
    let
      missing = filter (path: !fileExists path) paths;
    in
    {
      valid = missing == [ ];
      missing = missing;
      message =
        if missing == [ ] then "All required files exist" else "Missing files: ${toString missing}";
    };

  # Validate file contains all required patterns
  validateFilePatterns =
    path: patterns:
    let
      missing = filter (pattern: !fileContains path pattern) patterns;
    in
    {
      valid = missing == [ ];
      path = path;
      missing = missing;
      message =
        if missing == [ ] then
          "File ${path} contains all required patterns"
        else
          "File ${path} missing patterns: ${toString missing}";
    };
}
