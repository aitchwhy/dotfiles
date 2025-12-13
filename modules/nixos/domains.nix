# Domain pipelines support for cloud VM
# Provides Python, UV, DVC, and data analysis tools
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Python environment for health/finance pipelines
  environment.systemPackages = with pkgs; [
    # Python runtime
    python314

    # Package management
    uv

    # Data version control
    dvc

    # GCS support for DVC
    google-cloud-sdk

    # Data analysis tools (optional, for interactive use)
    ruff # Linting

    # Git (for DVC)
    git
    git-lfs
  ];

  # Allow DVC to work with GCS via ADC (Application Default Credentials)
  # The VM's service account provides access to GCS buckets
  # Note: gcp-observability.nix may override with explicit credentials path
  environment.variables = {
    # DVC will use ADC automatically when running on GCP
    GOOGLE_APPLICATION_CREDENTIALS = lib.mkDefault "";
  };

  # Create domains directory structure
  systemd.tmpfiles.rules = [
    "d /home/hank/domains 0755 hank users -"
    "d /home/hank/domains/health 0755 hank users -"
    "d /home/hank/domains/finance 0755 hank users -"
  ];
}
