# Nix first
[[ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]] && . "$HOME/.nix-profile/etc/profile.d/nix.sh"

# Then your paths
[[ -f "$HOME/.config/shell/path_utils.sh" ]] && . "$HOME/.config/shell/path_utils.sh"