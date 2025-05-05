# Shell wrapper to ensure Nix uses zsh instead of bash
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [];
  shellHook = ''
    # Force the use of zsh for the shell
    SHELL_PATH=$(which zsh)
    if [ -n "$SHELL_PATH" ]; then
      echo "Switching to zsh..."
      exec "$SHELL_PATH"
    else
      echo "zsh not found, staying in current shell."
    fi
  '';
}