# Terranix and OpenTofu for infrastructure as code
# Pure Nix -> Terraform JSON -> OpenTofu apply
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.infrastructure.terranix;
in
{
  options.modules.infrastructure.terranix = {
    enable = lib.mkEnableOption "Terranix and OpenTofu tooling";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      opentofu
      terranix
    ];

    programs.zsh.shellAliases = {
      tf = "tofu";
      tfp = "tofu plan";
      tfa = "tofu apply";
      tfi = "tofu init";
      tfd = "tofu destroy";
      tfo = "tofu output";
      tfs = "tofu state";
    };
  };
}
