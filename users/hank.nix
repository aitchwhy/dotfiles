# User-specific configuration
# This file contains:
# - Personal development tools and language toolchains
# - Cloud platform CLIs and infrastructure tools
# - User-specific Git configuration
# - Personal productivity tools
{ pkgs, ... }:
{
  # Import home modules
  imports = [ ../modules/home ];

  # User identity
  home = {
    username = "hank";
    homeDirectory = "/Users/hank";
    stateVersion = "26.05";
  };

  # Git configuration
  modules.home.tools.git = {
    userName = "Hank Lee";
    userEmail = "hank.lee.qed@gmail.com";
  };

  # Packages managed by modules/home/packages/
  # - common.nix: Cross-platform tools (cloud, k8s, languages, databases)
  # - darwin.nix: macOS-specific (docker-client, opentofu, iina, keka, gum)

  # Language-specific configurations
  home.sessionVariables = {
    GOPATH = "$HOME/go";
    CARGO_HOME = "$HOME/.cargo";
    RUSTUP_HOME = "$HOME/.rustup";
    PNPM_HOME = "$HOME/.pnpm";
  };

  home.sessionPath = [
    "$GOPATH/bin"
    "$CARGO_HOME/bin"
    "$PNPM_HOME"
    "$HOME/.local/bin"
  ];
}
