# treefmt-nix configuration
# Enables `nix fmt` and formatting checks via `nix flake check`
#
# Usage:
#   nix fmt              - Format all Nix files
#   nix fmt -- --check   - Check formatting without modifying
#   nix flake check      - Includes formatting check
{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { ... }:
    {
      treefmt = {
        # Root marker for treefmt to find project root
        projectRootFile = "flake.nix";

        # Enable nixfmt (nixfmt-rfc-style is now the default)
        programs.nixfmt = {
          enable = true;
          # Exclude files with shell heredocs - nixfmt mangles indentation
          # which breaks the heredoc content. See: https://github.com/NixOS/nixfmt/issues/91
          # Remove when nixfmt supports `# nixfmt: off` directive
          excludes = [
            "modules/home/apps/claude.nix" # activation scripts with heredocs
          ];
        };
      };
    };
}
