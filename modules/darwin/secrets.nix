# Darwin secrets configuration via sops-nix
# Manages encrypted secrets for macOS
#
# Usage:
#   1. Create secrets/darwin.yaml from template
#   2. Encrypt: sops secrets/darwin.yaml
#   3. Reference them: config.sops.secrets.<name>.path
#
# To edit encrypted secrets:
#   sops secrets/darwin.yaml
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkDefault
    pathExists
    ;
  cfg = config.modules.darwin.secrets;
  secretsFile = ../../secrets/darwin.yaml;
  secretsExist = pathExists secretsFile;
in
{
  options.modules.darwin.secrets = {
    enable = mkEnableOption "sops-nix secrets for Darwin";
  };

  config = mkIf (cfg.enable && secretsExist) {
    # Age key location (standard macOS path)
    sops.age.keyFile = mkDefault "/Users/${config.system.primaryUser}/.config/sops/age/keys.txt";

    # Default secrets file
    sops.defaultSopsFile = mkDefault secretsFile;

    # Define available secrets
    sops.secrets = {
      # Tailscale auth key for automatic authentication
      # Generate at: https://login.tailscale.com/admin/settings/keys
      # Choose: Reusable, Pre-authorized, Tags (if using ACLs)
      tailscale-auth = {
        # Permissions: root-readable (needed by launchd daemon)
        mode = "0400";
      };

      # GitHub Personal Access Token for MCP server
      # Generate at: https://github.com/settings/tokens
      # Scopes needed: repo, read:org, read:user
      github-token = {
        mode = "0400";
        owner = config.system.primaryUser;
        path = "/Users/${config.system.primaryUser}/.config/claude/github-token";
      };
    };
  };
}
