# Infrastructure modules
# Terranix (Nix -> Terraform JSON -> OpenTofu)
{ ... }:
{
  imports = [
    ./terranix.nix
  ];
}
