# Library exports for dotfiles
#
# Usage: import this from modules to access shared utilities
# Example: let lib' = import ../lib; in lib'.ports.infrastructure.ssh
{
  # Port registry - SSOT for all service ports
  ports = import ./ports.nix;
}
