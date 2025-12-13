# NixOS module aggregator
# Provides system configuration for cloud/remote Linux hosts
{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  imports = [
    ./system.nix
    ./security.nix
    ./users.nix
    ./domains.nix
    ./services/sshd.nix
    ./services/tailscale.nix
    ./services/docker.nix
    ./services/gcp-observability.nix
  ];

  config = {
    # System identification
    system.stateVersion = mkDefault "26.05";

    # Enable Nix flakes
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
    };

    # Timezone (US East for cloud-dev)
    time.timeZone = mkDefault "America/New_York";

    # Locale
    i18n.defaultLocale = mkDefault "en_US.UTF-8";

    # Console configuration
    console = {
      font = "Lat2-Terminus16";
      keyMap = mkDefault "us";
    };

    # Minimal packages - add more via flake overlays later
    environment.systemPackages = with pkgs; [
      git
      curl
      htop
    ];

    # Minimal programs
    programs = {
      git.enable = true;
    };

    # Use binary caches for faster builds
    nix.settings.substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    nix.settings.trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}
