# Utility functions for Nix configurations
{ lib }:

with lib;

rec {
  # Platform conditionals
  mkIfDarwin = condition: content: mkIf (condition && stdenv.isDarwin) content;
  mkIfLinux = condition: content: mkIf (condition && stdenv.isLinux) content;
  mkIfHome = condition: content: mkIf (condition && (config.home or false)) content;

  # Filter enabled items from an attribute set
  filterEnabled = attrs: filterAttrs (_n: v: v.enable or false) attrs;

  # Merge lists with deduplication
  mergeLists = lists: unique (flatten lists);

  # Recursively merge attribute sets
  recursiveMerge = attrList:
    fold (attr: acc: recursiveUpdate acc attr) { } attrList;

  # Convert package name to derivation
  pkgToDrv = pkgs: name:
    if isString name then pkgs.${name}
    else name;

  # Map packages from strings or derivations
  mapPackages = pkgs: packages:
    map (pkgToDrv pkgs) packages;

  # Create a conditional module
  mkConditionalModule = condition: module:
    mkIf condition (import module);

  # Get home directory for a user
  getHomeDir = username: system:
    if system == "darwin" then "/Users/${username}"
    else "/home/${username}";

  # Check if running in CI
  isCI = builtins.getEnv "CI" != "";

  # Get current system
  currentSystem = builtins.currentSystem or "x86_64-linux";

  # Create platform-specific aliases
  mkPlatformAliases = darwin: linux:
    if stdenv.isDarwin then darwin else linux;

  # Safe attribute access with default
  getAttrOr = default: path: attrs:
    attrByPath path default attrs;

  # Check if attribute path exists
  hasAttrPath = path: attrs:
    hasAttrByPath path attrs;

  # Convert string to path safely
  toPathSafe = str:
    if isString str then /. + str else str;

  # Get config value with fallback
  getCfg = path: default: config:
    getAttrOr default path config;
}
