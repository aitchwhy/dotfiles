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

  # Generic MCP secrets path (not Claude-specific)
  # Used by: Claude Code, Claude Desktop, Gemini CLI, and other agentic IDEs
  mcpSecretsPath = "/Users/${config.system.primaryUser}/.config/mcp";
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

      # ═══════════════════════════════════════════════════════════════════════════
      # MCP Server Secrets (Generic path for Claude Code, Desktop, Gemini CLI, etc.)
      # ═══════════════════════════════════════════════════════════════════════════

      # GitHub Personal Access Token for MCP server
      # Generate at: https://github.com/settings/tokens
      # Scopes needed: repo, read:org, read:user
      github-token = {
        mode = "0400";
        owner = config.system.primaryUser;
        path = "${mcpSecretsPath}/github-token";
      };

      # Claude Code userID for analytics/preferences
      # Enables pure declarative ~/.claude.json generation
      claude-user-id = {
        mode = "0400";
        owner = config.system.primaryUser;
        path = "${mcpSecretsPath}/claude-user-id";
      };

      # Exa AI API Key for code context search MCP server
      # Get at: https://exa.ai/
      # Used by: exa-mcp-server (get_code_context_exa, web_search_exa)
      exa-api-key = {
        mode = "0400";
        owner = config.system.primaryUser;
        path = "${mcpSecretsPath}/exa-api-key";
      };

      # Ref.tools API Key for documentation search MCP server
      # Get at: https://ref.tools/
      # Used by: Ref HTTP MCP (60-95% fewer tokens than alternatives)
      ref-api-key = {
        mode = "0400";
        owner = config.system.primaryUser;
        path = "${mcpSecretsPath}/ref-api-key";
      };

      # Linear API Key for issue tracking MCP server
      # Get at: https://linear.app/<workspace>/settings/api
      # Used by: @anthropic-ai/linear-mcp
      linear-api-key = {
        mode = "0400";
        owner = config.system.primaryUser;
        path = "${mcpSecretsPath}/linear-api-key";
      };
    };
  };
}
